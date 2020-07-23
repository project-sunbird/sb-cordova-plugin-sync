package org.sunbird.sync.model;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by swayangjit on 25/3/20.
 */
public class Request {
    private String host;
    private String path;
    private String type;
    private JSONObject headers;
    private Object body;
    private String serializer;
    private int noOfFailureSync;

    public Request(String host, String path, String type, JSONObject headers, String serializer, Object body) {
        this.host = host;
        this.path = path;
        this.type = type;
        this.headers = headers;
        this.serializer = serializer;
        this.body = body;
    }

    public String getHost() {
        return host;
    }

    public String getPath() {
        return path;
    }

    public String getType() {
        return type;
    }

    public JSONObject getHeaders() {
        return headers;
    }

    public void setHeaders(JSONObject headers){
        this.headers = headers;
    }

    public Object getBody() {
        return body;
    }

    public String getSerializer() {
        return serializer;
    }

    public int getNoOfFailureSync() {
        return noOfFailureSync;
    }

    public void setNoOfFailureSync(int noOfFailureSync) {
        this.noOfFailureSync = noOfFailureSync;
    }

    @Override
    public String toString() {
        return "Request{" +
                "host='" + host + '\'' +
                ", path='" + path + '\'' +
                ", type='" + type + '\'' +
                ", headers=" + headers.toString() +
                ", body='" + body + '\'' +
                ", serializer='" + serializer + '\'' +
                '}';
    }

    public JSONObject toJSON() throws JSONException {
        JSONObject request = new JSONObject();
        request.put("host", host);
        request.put("type", type);
        request.put("path", path);
        request.put("headers", headers);
        request.put("serializer", serializer);
        request.put("body", body);
        request.put("noOfFailureSync", noOfFailureSync);
        return request;
    }
}
