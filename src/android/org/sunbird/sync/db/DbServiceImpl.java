package org.sunbird.sync.db;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.sunbird.db.SQLiteOperator;
import org.sunbird.db.SunbirdDBHelper;

/**
 * Created by swayangjit on 27/3/20.
 */
public class DbServiceImpl implements DbService {
    @Override
    public JSONArray seed() throws JSONException {
        JSONArray resultArray = getOperator().execute("SELECT * from network_queue");
        return resultArray;
    }

    @Override
    public long insert(JSONObject request) throws JSONException {
        long id = getOperator().insert("network_queue", request);
        return id;
    }

    @Override
    public long delete(String id) throws JSONException {
        JSONArray resultArray = getOperator().execute("DELETE from network_queue where msg_id='" +id+"'");
        return 0;
    }

    @Override
    public long update(String selection, String[] whereArgs,JSONObject model) throws JSONException {
        return getOperator().update("network_queue", selection+" = ?", whereArgs, model);
    }

    @Override
    public JSONArray read(String table, String[] coloumns, String selection, String selectionArgs) throws JSONException {
        JSONArray resultArray = getOperator().read(false, table, coloumns, selection, new String[]{selectionArgs}, "", "", "", "");
        return resultArray;
    }

    private SQLiteOperator getOperator() {
        return SunbirdDBHelper.getInstance().operator(false);
    }
}
