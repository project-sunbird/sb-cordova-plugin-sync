package org.sunbird.sync.network;


import android.util.Base64;
import android.util.Log;

import com.silkimen.http.HttpBodyDecoder;
import com.silkimen.http.HttpRequest;
import com.silkimen.http.JsonUtils;
import com.silkimen.http.OkConnectionFactory;
import com.silkimen.http.TLSConfiguration;

import org.json.JSONException;
import org.json.JSONObject;
import org.sunbird.sync.model.HttpResponse;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;

import javax.net.ssl.SSLException;

/**
 * Created by swayangjit on 27/3/20.
 */
public class HttpOperation {
    protected static final String TAG = "Cordova-Plugin-SYNC";
    private String method;
    private String url;
    private Object data;
    private String serializer = "none";
    private String responseType = "text";
    private JSONObject headers;
    private int timeout = 60000;
    private boolean followRedirects = true;
    private TLSConfiguration tlsConfiguration;

    public HttpOperation(String method, String url, String serializer, Object data, JSONObject headers, TLSConfiguration tlsConfiguration) {

        this.method = method;
        this.url = url;
        this.serializer = serializer;
        this.data = data;
        this.headers = headers;
        this.tlsConfiguration = tlsConfiguration;
    }

    public HttpResponse execute() {
        HttpResponse response = new HttpResponse();

        try {
            HttpRequest request = this.createRequest();
            this.prepareRequest(request);
            this.sendBody(request);
            this.processResponse(request, response);
        } catch (HttpRequest.HttpRequestException e) {
            if (e.getCause() instanceof SSLException) {
                response.setStatus(-2);
                response.setErrorMessage("TLS connection could not be established: " + e.getMessage());
                Log.w(TAG, "TLS connection could not be established", e);
            } else if (e.getCause() instanceof UnknownHostException) {
                response.setStatus(-3);
                response.setErrorMessage("Host could not be resolved: " + e.getMessage());
                Log.w(TAG, "Host could not be resolved", e);
            } else if (e.getCause() instanceof SocketTimeoutException) {
                response.setStatus(-4);
                response.setErrorMessage("Request timed out: " + e.getMessage());
                Log.w(TAG, "Request timed out", e);
            } else {
                response.setStatus(-1);
                response.setErrorMessage("There was an error with the request: " + e.getCause().getMessage());
                Log.w(TAG, "Generic request error", e);
            }
        } catch (Exception e) {
            response.setStatus(-1);
            response.setErrorMessage(e.getMessage());
            Log.e(TAG, "An unexpected error occured", e);
        }
        return response;
    }

    private HttpRequest createRequest() throws JSONException {
        return new HttpRequest(this.url, this.method);
    }

    private void prepareRequest(HttpRequest request) throws JSONException, IOException {
        request.followRedirects(this.followRedirects);
        request.readTimeout(this.timeout);
        request.acceptCharset("UTF-8");
        request.uncompress(true);
        HttpRequest.setConnectionFactory(new OkConnectionFactory());
        if (this.tlsConfiguration.getHostnameVerifier() != null) {
            request.setHostnameVerifier(this.tlsConfiguration.getHostnameVerifier());
        }
        request.setSSLSocketFactory(this.tlsConfiguration.getTLSSocketFactory());
        this.setContentType(request);
        request.headers(JsonUtils.getStringMap(this.headers));
    }

    private void setContentType(HttpRequest request) {
        if ("json".equals(this.serializer)) {
            request.contentType("application/json", "UTF-8");
        } else if ("raw".equals(this.serializer)) {
            request.contentType("application/octet-stream");
        }
    }

    private void sendBody(HttpRequest request) throws Exception {
        if (this.data == null) {
            return;
        }

        if ("json".equals(this.serializer)) {
            request.send(this.data.toString());
        } else if ("raw".equals(this.serializer)) {
            request.send(Base64.decode((String) this.data, Base64.DEFAULT));
        }
    }

    private void processResponse(HttpRequest request, HttpResponse response) throws Exception {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        request.receive(outputStream);

        response.setStatus(request.code());
        response.setUrl(request.url().toString());
        response.setHeaders(request.headers());

        if (request.code() >= 200 && request.code() < 300) {
            if ("text".equals(this.responseType) || "json".equals(this.responseType)) {
                String decoded = HttpBodyDecoder.decodeBody(outputStream.toByteArray(), request.charset());
                response.setBody(decoded);
            } else {
                response.setData(outputStream.toByteArray());
            }
        } else {
            response.setErrorMessage(HttpBodyDecoder.decodeBody(outputStream.toByteArray(), request.charset()));
        }
    }
}
