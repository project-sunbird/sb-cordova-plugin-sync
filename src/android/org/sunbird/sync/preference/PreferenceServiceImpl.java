package org.sunbird.sync.preference;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by swayangjit on 9/6/20.
 */

public class PreferenceServiceImpl implements PreferenceService {
    private SharedPreferences mSharedPrefs;

    public PreferenceServiceImpl(Context context) {
        mSharedPrefs = context.getApplicationContext().getSharedPreferences("org.ekstep.genieservices.preference_file", Context.MODE_PRIVATE);
    }

    @Override
    public String getBearerToken() {
        return mSharedPrefs.getString("api_bearer_token_v2", null);
    }

    @Override
    public String getUserToken() {
        String oauthToken = mSharedPrefs.getString("oauth_token", null);
        if (oauthToken == null) {
            return null;
        }
        try {
            JSONObject oauthTokenJson = new JSONObject(oauthToken);
            return oauthTokenJson.optString("access_token");
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }

    @Override
    public String getManagedUserToken() {
        String oauthToken = mSharedPrefs.getString("oauth_token", null);
        if (oauthToken == null) {
            return null;
        }
        try {
            JSONObject oauthTokenJson = new JSONObject(oauthToken);
            return oauthTokenJson.optString("managed_access_token");
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }
}
