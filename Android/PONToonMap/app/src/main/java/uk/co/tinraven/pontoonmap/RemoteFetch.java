package uk.co.tinraven.pontoonmap;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import org.json.JSONArray;
import org.json.JSONObject;

import android.os.Build;
import android.util.Log;
import android.util.Base64;

import androidx.annotation.RequiresApi;

public class RemoteFetch {
 
    private static final String APIURL = "COMMUNITYAPI_LINK_HERE";
    private static final String APIKEY = "INSERT_API_KEY_HERE";

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static JSONObject login(String username, String password){
        try {
            URL url = new URL(APIURL+"login"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream()));

            StringBuffer json = new StringBuffer(1024);
            String tmp="";
            while((tmp=reader.readLine())!=null)
                json.append(tmp).append("\n");
            reader.close();
            connection.disconnect();

            JSONObject data = new JSONObject(json.toString());

            return data;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static JSONArray getPins(String username, String password){
        try {
            URL url = new URL(APIURL+"pins"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream()));

            StringBuffer json = new StringBuffer(1024);
            String tmp="";
            while((tmp=reader.readLine())!=null)
                json.append(tmp).append("\n");
            reader.close();
            connection.disconnect();

            JSONArray data = new JSONArray(json.toString());

            return data;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return null;
        }
    }


    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static JSONObject postPin(String username, String password, JSONObject obj){
        try {
            URL url = new URL(APIURL+"pins"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-type", "application/json; charset=utf-8");
            connection.setRequestProperty("Accept", "application/json; charset=utf-8");
            connection.setDoOutput(true);

            try(OutputStream os = connection.getOutputStream()) {
                byte[] input = obj.toString().getBytes("utf-8");
                os.write(input, 0, input.length);
                os.flush();
                os.close();
            }


            int code = connection.getResponseCode();
            Log.e("PONTRESPONSE ", connection.getResponseMessage());


            if (code == 200) {
                BufferedReader reader = new BufferedReader(
                        new InputStreamReader(connection.getInputStream()));

                StringBuffer json = new StringBuffer(1024);
                String tmp="";
                while((tmp=reader.readLine())!=null)
                    json.append(tmp).append("\n");
                reader.close();
                connection.disconnect();

                JSONObject data = new JSONObject(json.toString());
                return data;
            } else
                return null;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static boolean deletePin(String username, String password, Integer pinId){
        try {
            URL url = new URL(APIURL+"pins/delete"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-type", "application/json; charset=utf-8");
            connection.setRequestProperty("Accept", "application/json; charset=utf-8");
            connection.setDoOutput(true);

            try(OutputStream os = connection.getOutputStream()) {
                JSONObject obj = new JSONObject();
                obj.put("id",pinId);
                byte[] input = obj.toString().getBytes("utf-8");
                os.write(input, 0, input.length);
                os.flush();
                os.close();
            }

            int code = connection.getResponseCode();
            connection.disconnect();

            if (code == 204)
                return true;
            else
                return false;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return false;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static JSONArray getUsers(String username, String password){
        try {
            URL url = new URL(APIURL+"training-centre/users"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream()));

            StringBuffer json = new StringBuffer(1024);
            String tmp="";
            while((tmp=reader.readLine())!=null)
                json.append(tmp).append("\n");
            reader.close();
            connection.disconnect();

            JSONArray data = new JSONArray(json.toString());

            return data;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static boolean updateUsers(String username, String password, JSONObject obj){
        try {
            URL url = new URL(APIURL+"training-centre/users"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-type", "application/json; charset=utf-8");
            connection.setRequestProperty("Accept", "application/json; charset=utf-8");
            connection.setDoOutput(true);

            try(OutputStream os = connection.getOutputStream()) {
                byte[] input = obj.toString().getBytes("utf-8");
                os.write(input, 0, input.length);
                os.flush();
                os.close();
            }

            int code = connection.getResponseCode();
            connection.disconnect();

            if (code == 200)
                return true;
            else
                return false;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return false;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static JSONArray getTrainingCentres(String username, String password){
        try {
            URL url = new URL(APIURL+"user/training-centres"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream()));

            StringBuffer json = new StringBuffer(1024);
            String tmp="";
            while((tmp=reader.readLine())!=null)
                json.append(tmp).append("\n");
            reader.close();
            connection.disconnect();

            JSONArray data = new JSONArray(json.toString());

            return data;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static boolean deleteTrainingCentre(String username, String password, String name){
        try {
            URL url = new URL(APIURL+"user/training-centres/remove"+APIKEY);
            HttpURLConnection connection =
                    (HttpURLConnection)url.openConnection();

            String string = username+":"+password;
            byte[] byteArray = string.getBytes("UTF-8");
            connection.addRequestProperty("Authorization", "Basic "+Base64.encodeToString(byteArray, Base64.DEFAULT));
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-type", "application/json; charset=utf-8");
            connection.setRequestProperty("Accept", "application/json; charset=utf-8");
            connection.setDoOutput(true);

            try(OutputStream os = connection.getOutputStream()) {
                JSONObject obj = new JSONObject();
                obj.put("email",name);
                byte[] input = obj.toString().getBytes("utf-8");
                os.write(input, 0, input.length);
                os.flush();
                os.close();
            }

            int code = connection.getResponseCode();
            connection.disconnect();

            if (code == 204)
                return true;
            else
                return false;
        }catch(Exception e){
            Log.e("PONTRESPONSE exception", e.getMessage());
            return false;
        }
    }
}