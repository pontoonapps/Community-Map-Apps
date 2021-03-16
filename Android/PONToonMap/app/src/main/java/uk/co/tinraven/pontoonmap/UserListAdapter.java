package uk.co.tinraven.pontoonmap;

import android.content.ClipData;
import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;
import android.widget.ToggleButton;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;

public class UserListAdapter extends ArrayAdapter
{
    ArrayList<ListItem> userList = new ArrayList<>();
    boolean user;

    public UserListAdapter(MapsMarkerActivity mapsMarkerActivity, int activity_listview, ArrayList<ListItem> newList) {
        super(mapsMarkerActivity, activity_listview, newList);
        userList = newList;
    }

    @Override
    public int getCount() {
        return super.getCount();
    }

    public void setUserRole(boolean state) {
        user = state;
    }

    public boolean getState(int index) {
        return userList.get(index).enabled;
    }

    public void remove(int index) {
        userList.remove(index);
    }

    public void add(int index, ListItem item) {
        userList.add(item);
    }

    public void update(ArrayList<ListItem> newList) {
        userList = newList;
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {

        View v = convertView;
        LayoutInflater inflater = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        v = inflater.inflate(R.layout.activity_listview, null);
        TextView textView = (TextView) v.findViewById(R.id.label);
        textView.setText(userList.get(position).getName());
        ToggleButton toggle = (ToggleButton) v.findViewById(R.id.toggle);
        if (user) {
            toggle.setVisibility(View.VISIBLE);
            toggle.setChecked(userList.get(position).getEnabled());
            toggle.setOnClickListener(new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                userList.get(position).enabled = !userList.get(position).enabled;
                }
            });
        } else {
            toggle.setVisibility(View.INVISIBLE);
        }
        return v;
    }

}