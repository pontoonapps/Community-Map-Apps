package uk.co.tinraven.pontoonmap;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.location.Location;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.os.Handler;
import android.text.Html;
import android.text.InputType;
import android.text.method.LinkMovementMethod;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.PopupWindow;
import android.widget.TableLayout;
import android.widget.TextView;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.BitmapDescriptor;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import static android.content.DialogInterface.BUTTON_POSITIVE;

public class MapsMarkerActivity extends AppCompatActivity
        implements OnMapReadyCallback, GoogleMap.OnMarkerClickListener, GoogleMap.OnInfoWindowClickListener,
        GoogleMap.OnMapClickListener, GoogleMap.OnMapLongClickListener {

    private PopupWindow popupWindow;
    private GoogleMap mMap;
    private static final int PERMISSIONS_REQUEST_ACCESS_FINE_LOCATION = 1;
    private boolean mLocationPermissionGranted;

    private static String username = "";
    private static String password = "";
    private boolean loggedIn = false;
    private boolean editing = false;
    private boolean roleUser = true;
    private JSONArray pins;
    private JSONObject userData;
    private ArrayList<String> userEmailList = new ArrayList<String>();
    private String newTrainingCentreNames;
    private ArrayList<String> trainingCentreEmails = new ArrayList<String>();
    private ArrayList<String> trainingCentreNames = new ArrayList<String>();
    private ArrayList<Boolean> trainingCentrePinsVisible = new ArrayList<Boolean>();

    private String tmpName;
    private Integer tmpId;
    private JSONObject tmpPin;
    private ArrayList<ListItem> tmpNewList=new ArrayList<>();

    private ArrayList<Marker> mMarkerArray = new ArrayList<Marker>();
    //private int markerFilter;
    private FusedLocationProviderClient mFusedLocationProviderClient;

    private View popupView;
    private UserListAdapter listAdapter;
    private Button addButton;
    private Button removeButton;

    // Need handler for callbacks to the UI thread
    final Handler mHandler = new Handler();

    final Runnable mLoginFailed = new Runnable() {
        public void run() {
            loginFailed();
        }
    };

    final Runnable mPostFailed = new Runnable() {
        public void run() {
            postFailed();
        }
    };

    final Runnable mPostSucceeded = new Runnable() {
        public void run() {
            postSucceeded();
        }
    };

    final Runnable mSetupPins = new Runnable() {
        public void run() {
            saveUserDatafile();
            Button button = (Button)findViewById(R.id.button_login);
            button.setText(R.string.logout);
            setupPins();
        }
    };

    final Runnable mDeleteFailed = new Runnable() {
        public void run() {
            deleteFailed();
        }
    };

    final Runnable mAddFailed = new Runnable() {
        public void run() {
            addFailed();
        }
    };

    final Runnable mDeleteSucceeded = new Runnable() {
        public void run() {
            deleteSucceeded();
        }
    };

    final Runnable mGetDataFailed = new Runnable() {
        public void run() {
            getDataFailed();
        }
    };

    final Runnable mDisplayUserWindow = new Runnable() {
        public void run() {
            displayUserWindow();
        }
    };

    final Runnable mHandleUserData = new Runnable() {
        public void run() {
            handleUserData();
        }
    };

    final Runnable mListChanged = new Runnable() {
        public void run() {
            notifyDataSetChanged();
        }
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_maps);
        SupportMapFragment mapFragment = (SupportMapFragment) getSupportFragmentManager()
                .findFragmentById(R.id.map);
        mapFragment.getMapAsync(this);

        mFusedLocationProviderClient = LocationServices
                .getFusedLocationProviderClient(this);

        LinearLayout layout = (LinearLayout)findViewById(R.id.dataview);
        layout.getBackground().setAlpha(150);

        LayoutInflater inflater = (LayoutInflater)
                getSystemService(LAYOUT_INFLATER_SERVICE);
        popupView = inflater.inflate(R.layout.user_window, null);
        addButton = (Button)popupView.findViewById(R.id.button_add);
        removeButton = (Button)popupView.findViewById(R.id.button_remove);
    }



    // Users / Centres Window

    public void onClickUsersButton(View v) {
        if (roleUser) {
            new Thread() {
                @RequiresApi(api = Build.VERSION_CODES.KITKAT)
                public void run() {
                    final JSONArray json = RemoteFetch.getTrainingCentres(username, password);
                    if (json == null) {
                        mHandler.post(mGetDataFailed);
                    } else {
                        if (json != null) {
                            updateTrainingCentres(json);
                        }
                        mHandler.post(mDisplayUserWindow);
                    }
                }
            }.start();
        } else {
            new Thread() {
                @RequiresApi(api = Build.VERSION_CODES.KITKAT)
                public void run() {
                    final JSONArray json = RemoteFetch.getUsers(username, password);
                    if (json == null) {
                        mHandler.post(mGetDataFailed);
                    } else {
                        if (json != null) {
                            userEmailList.clear();
                            for (int i = 0; i < json.length(); i++) {
                                try {
                                    userEmailList.add(json.getString(i));
                                } catch (JSONException e) {
                                    e.printStackTrace();
                                }
                            }
                        }
                        mHandler.post(mDisplayUserWindow);
                    }
                }
            }.start();
        }
    }

    public void displayUserWindow() {

        View view = (View) findViewById(R.id.map);
        TextView text = (TextView)popupView.findViewById(R.id.list_title);
        final ListView listView = (ListView) popupView.findViewById(R.id.mobile_list);

        closeInfoview();

        removeButton.setEnabled(false);
        tmpNewList.clear();
        if (roleUser) {
            for (int i=0;i<trainingCentreNames.size();i++)
                tmpNewList.add(new ListItem(trainingCentreNames.get(i),trainingCentrePinsVisible.get(i)));
            listAdapter = new UserListAdapter(this,
                    R.layout.activity_listview, tmpNewList);
            text.setText(R.string.training_centres);
            addButton.setVisibility(View.GONE);
        } else {
            for (int i=0;i<userEmailList.size();i++)
                tmpNewList.add(new ListItem(userEmailList.get(i),true));
            listAdapter = new UserListAdapter(this,
                    R.layout.activity_listview, tmpNewList);
            text.setText(R.string.users_registered);
            addButton.setVisibility(View.VISIBLE);
        }

        listAdapter.setUserRole(roleUser);
        listView.setAdapter(listAdapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, final int position, long arg3) {
                listView.setItemChecked(position,true);
                removeButton.setEnabled(true);
            }
        });

        int width = LinearLayout.LayoutParams.WRAP_CONTENT;
        int height = LinearLayout.LayoutParams.WRAP_CONTENT;
        boolean focusable = false; // lets taps outside the popup also dismiss it
       popupWindow = new PopupWindow(popupView, width, height, focusable);
       popupWindow.setOnDismissListener(new PopupWindow.OnDismissListener() {

           @Override
           public void onDismiss() {
               if (roleUser && listAdapter != null) {
                   for (int i = 0; i < trainingCentrePinsVisible.size(); i++)
                       trainingCentrePinsVisible.set(i, listAdapter.getState(i));
                   getPins(username, password);
                   saveHiddenFile();
                   saveCentresFile();
               }
           }
       });
        popupWindow.showAtLocation(view, Gravity.CENTER, 0, 0);


    }

    public void onClickCloseButton(View v) {
        popupWindow.dismiss();
    }

    public void onClickAddButton(View v) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Add a user's email");

        final TableLayout layout = new TableLayout(this);
        layout.setPadding(200,0,200,0);

        final EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
        input.setHint("Email");

        layout.addView(input);
        builder.setView(layout);

        builder.setPositiveButton("Enter", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                tmpName = input.getText().toString();
                attemptAdd();
            }
        });

        builder.show();

    }

    public void onClickRemoveButton(View v) {
        ListView listView = (ListView) popupView.findViewById(R.id.mobile_list);
        final int removeIndex = listView.getCheckedItemPosition();
        listView.setItemChecked(removeIndex, false);
        removeButton.setEnabled(false);

        if (roleUser) {
            new Thread() {
                @RequiresApi(api = Build.VERSION_CODES.KITKAT)
                public void run() {
                    final boolean success = RemoteFetch.deleteTrainingCentre(username, password, trainingCentreEmails.get(removeIndex));
                    if (success) {
                        trainingCentreEmails.remove(removeIndex);
                        trainingCentreNames.remove(removeIndex);
                        trainingCentrePinsVisible.remove(removeIndex);
                        tmpNewList.clear();
                        for (int i=0;i<trainingCentreEmails.size();i++)
                            tmpNewList.add(new ListItem(trainingCentreEmails.get(i),trainingCentrePinsVisible.get(i)));
                        mHandler.post(mListChanged);
                    } else {
                        mHandler.post(mPostFailed);
                    }
                }
            }.start();
        } else {
            new Thread() {
                @RequiresApi(api = Build.VERSION_CODES.KITKAT)
                public void run() {
                    JSONObject update = new JSONObject();
                    try {
                        JSONArray array = new JSONArray();
                        array.put(userEmailList.get(removeIndex));
                        update.put("remove", array);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    final boolean success = RemoteFetch.updateUsers(username, password, update);
                    if (success) {
                        userEmailList.remove(removeIndex);
                        tmpNewList.clear();
                        for (int i=0;i<userEmailList.size();i++)
                            tmpNewList.add(new ListItem(userEmailList.get(i),true));
                        mHandler.post(mListChanged);
                    } else {
                        mHandler.post(mPostFailed);
                    }
                }
            }.start();
        }
    }

    private void attemptAdd(){
        if (!roleUser) {
            new Thread() {
                @RequiresApi(api = Build.VERSION_CODES.KITKAT)
                public void run() {
                    JSONObject update = new JSONObject();
                    try {
                        JSONArray array = new JSONArray();
                        array.put(tmpName);
                        update.put("add", array);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    final boolean success = RemoteFetch.updateUsers(username, password, update);
                    if (success) {
                        userEmailList.add(tmpName);
                        tmpNewList.clear();
                        for (int i=0;i<userEmailList.size();i++)
                            tmpNewList.add(new ListItem(userEmailList.get(i),true));
                        mHandler.post(mListChanged);
                    } else {
                        mHandler.post(mAddFailed);
                    }
                }
            }.start();
        }
    }

    public void notifyDataSetChanged() {
        if (listAdapter != null) {
            listAdapter.update(tmpNewList);
            listAdapter.notifyDataSetChanged();
        }
    }


    public void handleUserData() {
        Button button = (Button)findViewById(R.id.button_users);
        roleUser = true;
        button.setText(R.string.centres);
        try {
            if (userData.getString("role").equals("recruiter"))
            {
                roleUser = false;
                button.setText(R.string.users);
            } else {
                loadCentresFile();
                try {
                    JSONArray centres = userData.getJSONArray("training_centres");
                    if (centres != null)
                        updateTrainingCentres(centres);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        getPins(username, password);
    }

    private void updateTrainingCentres(JSONArray centres){
            JSONObject tmpNameObject;
            String tmpString;
            String name = "";
            StringBuilder sb = new StringBuilder();
            ArrayList<String> previousTrainingCentreEmails = new ArrayList<>(trainingCentreEmails);
            trainingCentreEmails.clear();
            trainingCentreNames.clear();
            trainingCentrePinsVisible.clear();
            for (int i=0;i<centres.length();i++){
                try {
                    JSONObject entry = centres.getJSONObject(i);
                    trainingCentreEmails.add(entry.getString("email"));
                    tmpNameObject = entry.getJSONObject("name");
                    tmpString = tmpNameObject.getString("first");
                    if (tmpString.length() > 0) {
                        name = tmpString;
                    }
                    tmpString = tmpNameObject.getString("last");
                    if (tmpString.length() > 0) {
                        if (name.length() > 0)
                            name = name + " " + tmpString;
                        else
                            name = tmpString;
                    }
                    trainingCentreNames.add(name);
                    trainingCentrePinsVisible.add(true);

                    if (previousTrainingCentreEmails.indexOf(entry.getString("email")) < 0){
                        sb.append(name);
                        sb.append("\n");
                    }
                    newTrainingCentreNames = sb.toString();
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            loadHiddenFile();
            saveCentresFile();
            if (newTrainingCentreNames != null && newTrainingCentreNames.length() > 0) {
                displayNewTrainingCentres();
            }
    }

    private void displayNewTrainingCentres(){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        if (builder != null) {
            builder.setTitle(R.string.new_training_centre);

            final TextView text = new TextView(this);
            if (text != null) {
                text.setText(String.format("%1$s\n%2$s",
                        getString(R.string.new_training_centres),newTrainingCentreNames));
                text.setPadding(0, 50, 0, 0);
                text.setGravity(Gravity.CENTER);
                builder.setView(text);
            }
        }

        builder.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
            }
        });

        builder.show();
    }

    public void onMapClick(LatLng point) {
        closeInfoview();
    }

    public void onMapLongClick(LatLng point) {
        addPinQuery(point);
    }

    public boolean onMarkerClick(final Marker marker) {
        JSONObject obj = (JSONObject)marker.getTag();
        try {
            TextView textview1 = (TextView)findViewById(R.id.text1);
            textview1.setText(obj.getString("address_line_1")+", "+obj.getString("address_line_2")+", "+obj.getString("postcode"));
            TextView textview2 = (TextView)findViewById(R.id.text2);
            textview2.setText(obj.getString("phone"));
            TextView textview3 = (TextView)findViewById(R.id.text3);
            textview3.setText(obj.getString("website"));
            TextView textview4 = (TextView)findViewById(R.id.text4);
            textview4.setText(obj.getString("notes"));
            TextView textview5 = (TextView)findViewById(R.id.text5);
            textview5.setText(obj.getString("description"));
            if (!obj.getBoolean("userPin")) {
                String tmp = obj.getString("training_centre_email");
                if (tmp != null) {
                    int i = trainingCentreEmails.indexOf(tmp);
                    if (i >= 0 && i < trainingCentreNames.size()) {
                        TextView textview6 = (TextView) findViewById(R.id.text6);
                        textview6.setText(trainingCentreNames.get(i));
                    }
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        openInfoview();

        return false;
    }


    public void directionsClicked(JSONObject obj) {
        try {
            double latitude = obj.getDouble("latitude");
            double longitude = obj.getDouble("longitude");

            String url = "https://www.google.com/maps/dir/?api=1&destination="+latitude+","+longitude+"&travelmode=transit";
            Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            startActivity(browserIntent);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }


    public void onInfoWindowClick(final Marker marker) { // Edit
        JSONObject obj = (JSONObject)marker.getTag();
        changePinQuery(obj);
    }

    public void onClickLoginButton(View v) {
        Button button = (Button)findViewById(R.id.button_login);
        if (loggedIn) {
            button.setText(R.string.login);
            this.getApplicationContext().deleteFile("user.dat");
            loggedIn = false;
            mMap.clear();
            mMarkerArray.clear();
            LinearLayout layout = (LinearLayout)findViewById(R.id.dataview);
            layout.getBackground().setAlpha(150);
        }
        attemptLogin();
    }

    public void onClickAddress(View v) {
        TextView textview = (TextView)findViewById(R.id.text1);
        String address = textview.getText().toString();
        String url = "https://www.google.com/maps/dir/?api=1&destination="+address+"&travelmode=transit";
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        startActivity(intent);
    }

    public void onClickPhone(View v) {
        TextView textview = (TextView)findViewById(R.id.text2);
        String phoneno = textview.getText().toString();
        if (phoneno.length() > 0) {
            Intent intent = new Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", phoneno, null));
            startActivity(intent);
        }
    }

    public void onClickURL(View v) {
        TextView textview = (TextView)findViewById(R.id.text3);
        String url = textview.getText().toString();
        if (url.length() > 0) {
            if (!url.startsWith("http://") && !url.startsWith("https://"))
                url = "http://" + url;
            Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            startActivity(browserIntent);
        }
    }

    private void getLocationPermission() {
        if (ContextCompat.checkSelfPermission(this.getApplicationContext(),
                android.Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED) {
            mLocationPermissionGranted = true;
            updateLocationUI();
        } else {
            ActivityCompat.requestPermissions(this,
                    new String[]{android.Manifest.permission.ACCESS_FINE_LOCATION},
                    PERMISSIONS_REQUEST_ACCESS_FINE_LOCATION);
        }
    }

    private void updateLocationUI() {
        if (mMap == null) {
            return;
        }
        try {
            if (mLocationPermissionGranted) {
                mMap.setMyLocationEnabled(true);
                mMap.getUiSettings().setMyLocationButtonEnabled(true);
                getDeviceLocation();
            } else {
                mMap.setMyLocationEnabled(false);
                mMap.getUiSettings().setMyLocationButtonEnabled(false);
                getLocationPermission();
            }
        } catch (SecurityException e)  {
            Log.e("Exception: %s", e.getMessage());
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           @NonNull String permissions[],
                                           @NonNull int[] grantResults) {
        mLocationPermissionGranted = false;
        switch (requestCode) {
            case PERMISSIONS_REQUEST_ACCESS_FINE_LOCATION: {
                // If request is cancelled, the result arrays are empty.
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    mLocationPermissionGranted = true;
                }
            }
        }
        updateLocationUI();
    }

    private void getDeviceLocation() {
        try {
            if (mLocationPermissionGranted) {
                Task<Location> locationResult = mFusedLocationProviderClient.getLastLocation();
                locationResult.addOnCompleteListener(new OnCompleteListener<Location>() {
                    @Override
                    public void onComplete(@NonNull Task<Location> task) {
                        if (task.isSuccessful()) {
                            // Set the map's camera position to the current location of the device.
                            Location location = task.getResult();
                            if (location != null) {
                                LatLng currentLatLng = new LatLng(location.getLatitude(),
                                        location.getLongitude());
                                CameraUpdate update = CameraUpdateFactory.newLatLngZoom(currentLatLng,
                                        14);
                                mMap.moveCamera(update);
                            }
                        }
                    }
                });
            }
        } catch (SecurityException e) {
            Log.e("Exception: %s", e.getMessage());
        }
    }

    @Override
    public void onMapReady(GoogleMap googleMap) {
        mMap = googleMap;
        LatLng portsmouth = new LatLng(50.793740, -1.106184);

        if (mLocationPermissionGranted) {
            getDeviceLocation();
        } else
            googleMap.moveCamera(CameraUpdateFactory.newLatLngZoom(portsmouth,14));

        googleMap.setOnMarkerClickListener(this);
        googleMap.setOnInfoWindowClickListener(this);
        googleMap.setOnMapClickListener(this);
        googleMap.setOnMapLongClickListener(this);

        getLocationPermission();

        loadPinsFile();

        if (loadUserDatafile()) {
            login(username, password);
        } else {
            attemptLogin();
        }
    }

    private BitmapDescriptor getMarkerIcon(int color) {
        float[] hsv = new float[3];
        Color.colorToHSV(color, hsv);
        return BitmapDescriptorFactory.defaultMarker(hsv[0]);
    }

    private void openInfoview() {
        LinearLayout layout = (LinearLayout)findViewById(R.id.dataview);
        ViewGroup.LayoutParams params = layout.getLayoutParams();
        params.height = 800;
        layout.setLayoutParams(params);
    }

    private void closeInfoview() {
        LinearLayout layout = (LinearLayout)findViewById(R.id.dataview);
        ViewGroup.LayoutParams params = layout.getLayoutParams();
        params.height = 110;
        layout.setLayoutParams(params);
    }

    private void attemptLogin(){
        AlertDialog dialog = new AlertDialog.Builder(this).create();
        dialog.setTitle(R.string.login);
        dialog.setCanceledOnTouchOutside(false);

        final TableLayout layout = new TableLayout(this);
        layout.setPadding(60,0,60,0);

        final EditText input1 = new EditText(this);
        input1.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
        input1.setHint(R.string.email);
        if (username != null)
            input1.setText(username);
        LinearLayout container1 = new LinearLayout(this);
        container1.setOrientation(LinearLayout.VERTICAL);
        container1.setPadding(100,0,100,0);
        container1.addView(input1);

        final EditText input2 = new EditText(this);
        input2.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        input2.setHint(R.string.password);
        LinearLayout container2 = new LinearLayout(this);
        container2.setOrientation(LinearLayout.VERTICAL);
        container2.setPadding(100,0,100,0);
        container2.addView(input2);

        ImageView image = new ImageView(this);
        image.setImageResource(R.drawable.interreg_pontoon_logo);
        image.setScaleType(ImageView.ScaleType.FIT_START);
        image.setAdjustViewBounds(true);
        image.setPadding(50,0,50,0);

        TextView textView1  = new TextView(this);
        textView1.setText(Html.fromHtml(getResources().getString(R.string.login_text1)));
        textView1.setTextAlignment(TextView.TEXT_ALIGNMENT_CENTER);
        textView1.setTextColor(Color.BLACK);
        textView1.setTextSize(13);
        textView1.setLinksClickable(true);
        textView1.setMovementMethod(LinkMovementMethod.getInstance());

        TextView textView2  = new TextView(this);
        textView2.setText(Html.fromHtml(getResources().getString(R.string.login_text2)));
        textView2.setTextAlignment(TextView.TEXT_ALIGNMENT_CENTER);
        textView2.setTextColor(Color.BLACK);
        textView2.setTextSize(13);
        textView2.setLinksClickable(true);
        textView2.setMovementMethod(LinkMovementMethod.getInstance());

        layout.addView(container1);
        layout.addView(container2);
        layout.addView(image);
        layout.addView(textView1);
        layout.addView(textView2);
        dialog.setView(layout);

        dialog.setButton(DialogInterface.BUTTON_POSITIVE, getString(R.string.enter),
                new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                username = input1.getText().toString();
                password = input2.getText().toString();
                login(username, password);
            }
        });

        dialog.show();
    }

    private void loginFailed(){
        AlertDialog dialog = new AlertDialog.Builder(this).create();
        if (dialog != null) {
            dialog.setTitle(R.string.login);
            dialog.setCanceledOnTouchOutside(false);

            final TextView text = new TextView(this);
            if (text != null) {
                text.setText(R.string.login_not_recognised);
                text.setPadding(0, 50, 0, 0);
                text.setGravity(Gravity.CENTER);
                dialog.setView(text);
            }
        }

        dialog.setButton(DialogInterface.BUTTON_POSITIVE,getString(R.string.ok),
                new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                attemptLogin();
            }
        });
        dialog.setButton(DialogInterface.BUTTON_NEGATIVE,getString(R.string.cancel),
                new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                setupPins();
                dialog.cancel();
            }
        });

        dialog.show();
    }

    private void addFailed(){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        if (builder != null) {
            builder.setTitle(R.string.error);

            final TextView text = new TextView(this);
            if (text != null) {
                text.setText(R.string.failed_to_add);
                text.setPadding(0, 50, 0, 0);
                text.setGravity(Gravity.CENTER);
                builder.setView(text);
            }
        }

        builder.setPositiveButton(R.string.retry, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                attemptAdd();
            }
        });
        builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void postFailed(){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        if (builder != null) {
            builder.setTitle(R.string.error);

            final TextView text = new TextView(this);
            if (text != null) {
                text.setText(R.string.failed_to_post);
                text.setPadding(0, 50, 0, 0);
                text.setGravity(Gravity.CENTER);
                builder.setView(text);
            }
        }

        builder.setPositiveButton(R.string.retry, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                postPin();
            }
        });
        builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void deleteFailed(){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        if (builder != null) {
            builder.setTitle(R.string.error);

            final TextView text = new TextView(this);
            if (text != null) {
                text.setText(R.string.delete_failed);
                text.setPadding(0, 50, 0, 0);
                text.setGravity(Gravity.CENTER);
                builder.setView(text);
            }
        }

// Set up the buttons
        builder.setPositiveButton(R.string.retry, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                deletePin(username, password, tmpId);
            }
        });
        builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void deleteSucceeded(){
        JSONObject obj;
        for(int i=0; i<pins.length(); i++) {
            try {
                obj = (JSONObject)pins.get(i);
                if (obj.getInt("id") == tmpId) {
                    closeInfoview();
                    pins.remove(i);
                    setupPins();
                    break;
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }
    private void getDataFailed(){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        if (builder != null) {
            builder.setTitle(R.string.error);

            final TextView text = new TextView(this);
            if (text != null) {
                text.setText(R.string.couldnt_get_data);
                text.setPadding(0, 50, 0, 0);
                text.setGravity(Gravity.CENTER);
                builder.setView(text);
            }
        }

        builder.setPositiveButton(getString(R.string.ok), null);

        builder.show();
    }

    public void selectViewCategory(View v){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.select_pin_category);

        final List<String> category = new ArrayList<String>();
        category.add(getString(R.string.button_1));
        category.addAll(Arrays.asList(
                getString(R.string.button_2),
                getString(R.string.button_3), getString(R.string.button_4),
                getString(R.string.button_5), getString(R.string.button_6),
                getString(R.string.button_7), getString(R.string.button_8),
                getString(R.string.button_9), getString(R.string.button_10),
                getString(R.string.button_11), getString(R.string.button_12),
                getString(R.string.button_13), getString(R.string.button_14),
                getString(R.string.button_15), getString(R.string.button_16)
        ));

        CharSequence[] cs = category.toArray(new CharSequence[category.size()]);
        builder.setItems(cs, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                // display selected category of pins
                for (Marker marker : mMarkerArray) {
                    JSONObject obj = (JSONObject)marker.getTag();
                    try {
                        int cat = obj.getInt("category");
                        if (cat == which || which == 0)
                            marker.setVisible(true);
                        else
                            marker.setVisible(false);
                        Button button = (Button)findViewById(R.id.button_pincategory);
                        button.setText(category.get(which));
                        closeInfoview();
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }

            }
        });

        builder.show();
    }

    private void selectCategory(final LatLng latlong, final JSONObject obj){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.select_pin_category);

        List<String> category = new ArrayList<String>();
        if (editing)
            category.add(getString(R.string.keep_current));
        category.addAll(Arrays.asList(
                getString(R.string.button_2),
                getString(R.string.button_3), getString(R.string.button_4),
                getString(R.string.button_5), getString(R.string.button_6),
                getString(R.string.button_7), getString(R.string.button_8),
                getString(R.string.button_9), getString(R.string.button_10),
                getString(R.string.button_11), getString(R.string.button_12),
                getString(R.string.button_13), getString(R.string.button_14),
                getString(R.string.button_15), getString(R.string.button_16)
        ));

        CharSequence[] cs = category.toArray(new CharSequence[category.size()]);
        builder.setItems(cs, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                if (editing && which == 0) {
                    try {
                        which = Integer.parseInt(obj.getString("category"));
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else if (!editing)
                    which = which + 1;
                editPinDetails(which, latlong, obj);
            }
        });

        builder.show();
    }

    private void changePinQuery(final JSONObject obj){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.pin_actions);

        String[] actions = {getString(R.string.directions), getString(R.string.edit), getString(R.string.delete)};
        builder.setItems(actions, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                switch (which) {
                    case 0: // Directions
                        directionsClicked(obj);
                        break;
                    case 1: // Edit
                        editing = true;
                        selectCategory(null, obj);
                        break;
                    case 2: // Delete
                        try {
                            tmpId = obj.getInt("id");
                            deletePin(username, password, tmpId);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                        dialog.cancel();
                        break;
                }
            }
        });
        builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void addPinQuery(final LatLng latlong){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.add_pin_here);

        builder.setPositiveButton(R.string.yes, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                editing = false;
                selectCategory(latlong, null);
            }
        });
        builder.setNegativeButton(R.string.no, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void editPinDetails(final int category, final LatLng latlong, final JSONObject obj){
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        if (editing)
            builder.setTitle(R.string.edit_pin);
        else
            builder.setTitle(R.string.add_pin);

        final TableLayout layout = new TableLayout(this);
        final EditText name = new EditText(this);
        name.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL);
        name.setHint(R.string.name);
        layout.addView(name);

        final EditText description = new EditText(this);
        description.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL);
        description.setHint(R.string.description);
        layout.addView(description);

        final EditText phone = new EditText(this);
        phone.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL);
        phone.setHint(R.string.phone);
        layout.addView(phone);

        final EditText website = new EditText(this);
        website.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL);
        website.setHint(R.string.website);
        layout.addView(website);

        final EditText email = new EditText(this);
        email.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
        email.setHint(R.string.email);
        layout.addView(email);

        final EditText address1 = new EditText(this);
        address1.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_POSTAL_ADDRESS);
        address1.setHint(R.string.address_line_1);
        layout.addView(address1);

        final EditText address2 = new EditText(this);
        address2.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_POSTAL_ADDRESS);
        address2.setHint(R.string.address_line_2);
        layout.addView(address2);

        final EditText postcode = new EditText(this);
        postcode.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_POSTAL_ADDRESS);
        postcode.setHint(R.string.postcode);
        layout.addView(postcode);

        final EditText notes = new EditText(this);
        notes.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL);
        notes.setHint(R.string.notes);
        layout.addView(notes);

        if (obj != null) {
            try {
                name.setText(obj.getString("name"));
                description.setText(obj.getString("description"));
                phone.setText(obj.getString("phone"));
                website.setText(obj.getString("website"));
                email.setText(obj.getString("email"));

                address1.setText(obj.getString("address_line_1"));
                address2.setText(obj.getString("address_line_2"));
                postcode.setText(obj.getString("postcode"));
                postcode.setText(obj.getString("postcode"));
                notes.setText(obj.getString("notes"));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        builder.setView(layout);

        if (editing)
            builder.setPositiveButton(R.string.update, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    try {
                        obj.put("name",name.getText());
                        obj.put("description",description.getText());
                        obj.put("phone",phone.getText());
                        obj.put("website",website.getText());
                        obj.put("email",email.getText());
                        obj.put("address_line_1",address1.getText());
                        obj.put("address_line_2",address2.getText());
                        obj.put("postcode",postcode.getText());
                        obj.put("notes",notes.getText());
                        obj.put("category",category);
                        tmpPin = obj;
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    postPin();
                }
            });
        else
            builder.setPositiveButton(R.string.add, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    JSONObject newObject = new JSONObject();
                    try {
                        newObject.put("name",name.getText());
                        newObject.put("description",description.getText());
                        newObject.put("phone",phone.getText());
                        newObject.put("website",website.getText());
                        newObject.put("email",email.getText());
                        newObject.put("address_line_1",address1.getText());
                        newObject.put("address_line_2",address2.getText());
                        newObject.put("postcode",postcode.getText());
                        newObject.put("notes",notes.getText());
                        newObject.put("latitude",latlong.latitude);
                        newObject.put("longitude",latlong.longitude);
                        newObject.put("category",category);
                        // add doesnt have id
                        newObject.remove("id");
                        tmpPin = newObject;
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    postPin();
                }
            });

        builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                editing = false;
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void postPin() {
        new Thread(){
            @RequiresApi(api = Build.VERSION_CODES.KITKAT)
            public void run(){
                JSONObject result = RemoteFetch.postPin(username, password, tmpPin);
                if(result != null){
                    Log.e("PONTRESPONSE pin post", "success");

                    try {
                        tmpId = result.getInt("id");
                        tmpPin.put("id", tmpId);
                        tmpPin.put("userPin", true);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }

                    mHandler.post(mPostSucceeded);
                } else {
                    Log.e("PONTRESPONSE pin post", "fail");
                    mHandler.post(mPostFailed);
                }
            }
        }.start();
    }

    private void postSucceeded() {
        if (editing) {
            JSONObject obj;
            try {
                tmpId = tmpPin.getInt("id");
            } catch (JSONException e) {
                e.printStackTrace();
            }
            for(int i=0; i<pins.length(); i++) {
                try {
                    obj = (JSONObject)pins.get(i);
                    if (obj.getInt("id") == tmpId) {
                        pins.put(i, tmpPin);
                        closeInfoview();
                        break;
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        } else
            pins.put(tmpPin);
        setupPins();
    }

    private void login(final String username, final String password){
        new Thread(){
            @RequiresApi(api = Build.VERSION_CODES.KITKAT)
            public void run(){
                final JSONObject json = RemoteFetch.login(username, password);
                if(json == null){
                    mHandler.post(mLoginFailed);
                } else {
                    loggedIn = true;
                    userData = json;
                    mHandler.post(mHandleUserData);
                }
            }
        }.start();
    }

    private void getPins(final String username, final String password){
        new Thread(){
            @RequiresApi(api = Build.VERSION_CODES.KITKAT)
            public void run(){
                final JSONArray json = RemoteFetch.getPins(username, password);
                if(json == null){
                    mHandler.post(mGetDataFailed);
                } else {
                    loggedIn = true;
                    pins = json;
                    mHandler.post(mSetupPins);
                }
            }
        }.start();
    }

    private void deletePin(final String username, final String password, final Integer pinId){
        new Thread(){
            @RequiresApi(api = Build.VERSION_CODES.KITKAT)
            public void run(){
                boolean result = RemoteFetch.deletePin(username, password, pinId);
                if(result)
                    mHandler.post(mDeleteSucceeded);
                else
                    mHandler.post(mDeleteFailed);
            }
        }.start();
    }

    private void addPinsToMap() {
        try {
            for (int i = 0; i < pins.length(); i++) {
                JSONObject obj = pins.getJSONObject(i);

                if (!(!obj.getBoolean("userPin") && trainingCentreEmails.indexOf(obj.getString("training_centre_email"))>=0 &&
                        !trainingCentrePinsVisible.get(trainingCentreEmails.indexOf(obj.getString("training_centre_email"))))
                ) {
                    Marker marker = mMap.addMarker(new MarkerOptions()
                            .position(new LatLng(obj.getDouble("latitude"), obj.getDouble("longitude")))
                            .title(obj.getString("name")).icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE))
                    );

                    switch (obj.getInt("category")) {
                        case 1: //Childcare
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(0));
                            break;
                        case 2: //Community Centre
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(30));
                            break;
                        case 3: //Cultural Sites
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(60));
                            break;
                        case 4: //Dentist
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(90));
                            break;
                        case 5: //Doctors Surgery
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(120));
                            break;
                        case 6: //Education
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(150));
                            break;
                        case 7: //Health
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(180));
                            break;
                        case 8: //Hospital / A&E
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(210));
                            break;
                        case 9: //Library
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(230));
                            break;
                        case 10: //Practical Life
                            //marker.setIcon(getMarkerIcon(getResources().getColor(R.color.colorPrimaryDark)));
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(260));
                            break;
                        case 11: //Transport
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(290));
                            break;
                        case 12: //Other
                            marker.setIcon(BitmapDescriptorFactory.defaultMarker(320));
                            break;
                        default:
                            break;
                    }

                    marker.setTag(obj);
                    mMarkerArray.add(marker);
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void setupPins() {

        LinearLayout layout = (LinearLayout)findViewById(R.id.dataview);
        layout.getBackground().setAlpha(255);
        mMap.clear();
        mMarkerArray.clear();

        if (pins != null) {
            savePinsFile();
            addPinsToMap();
        }
    }


    //file handling

    private boolean saveUserDatafile() {
        String data = username+"\n"+password;
        Writer writer = null;
        try {
            writer = new OutputStreamWriter(openFileOutput("user.dat", Context.MODE_PRIVATE));
            writer.write(data);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (writer != null) {
                try {
                    writer.close();
                    return true;
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return false;
    }

    private boolean loadUserDatafile() {
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new InputStreamReader(openFileInput("user.dat")));
            String line = "";
            username = null;
            password = null;
            while ((line = reader.readLine()) != null) {
                if (username == null)
                    username = line;
                else
                    password = line;
            }

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (reader != null){
                try {
                    reader.close();
                    return true;
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return false;
    }

    private boolean savePinsFile() {
        Writer writer = null;
        try {
            writer = new OutputStreamWriter(openFileOutput("pins.dat", Context.MODE_PRIVATE));
            writer.write(pins.toString());
            writer.close();
            return true;
        } catch (IOException e) {
            Log.e("File Exception: ", e.getMessage());
            return false;
        }
    }


    private boolean loadPinsFile() {
        BufferedReader reader = null;
        StringBuilder sb = new StringBuilder();
        try {
            reader = new BufferedReader(new InputStreamReader(openFileInput("pins.dat")));
            String line = "";
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            pins = new JSONArray(sb.toString());
            return true;
        } catch (IOException | JSONException e) {
            Log.e("File Exception: ", e.getMessage());
            return false;
        }
    }

    private boolean saveHiddenFile() {
        Writer writer = null;
        try {
            writer = new OutputStreamWriter(openFileOutput("hidden.dat", Context.MODE_PRIVATE));
            for(int i=0; i<trainingCentrePinsVisible.size(); i++)
            if (!trainingCentrePinsVisible.get(i))
                writer.write(trainingCentreEmails.get(i));
            writer.close();
            return true;
        } catch (IOException e) {
            Log.e("File Exception: ", e.getMessage());
            return false;
        }
    }

    private boolean loadHiddenFile() {
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new InputStreamReader(openFileInput("hidden.dat")));
            String line = "";
            while ((line = reader.readLine()) != null) {
                int index = trainingCentreEmails.indexOf(line);
                if (index >= 0)
                    trainingCentrePinsVisible.set(index, false);
            }
            return true;
        } catch (IOException e) {
            Log.e("File Exception: ", e.getMessage());
            return false;
        }
    }

    private boolean saveCentresFile() {
        Writer writer = null;
        try {
            writer = new OutputStreamWriter(openFileOutput("centres.dat", Context.MODE_PRIVATE));
            for(int i=0; i<trainingCentreEmails.size(); i++)
                writer.write(trainingCentreEmails.get(i));
            writer.close();
            return true;
        } catch (IOException e) {
            Log.e("File Exception: ", e.getMessage());
            return false;
        }
    }

    private boolean loadCentresFile() {
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new InputStreamReader(openFileInput("centres.dat")));
            String line = "";
            trainingCentreEmails.clear();
            while ((line = reader.readLine()) != null)
                trainingCentreEmails.add(line);
            return true;
        } catch (IOException e) {
            Log.e("File Exception: ", e.getMessage());
            return false;
        }
    }

    }
