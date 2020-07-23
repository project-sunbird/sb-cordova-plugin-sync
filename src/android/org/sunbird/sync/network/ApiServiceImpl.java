package org.sunbird.sync.network;

import android.util.Log;

import com.silkimen.http.TLSConfiguration;

import org.sunbird.sync.model.HttpResponse;
import org.sunbird.sync.model.Request;

import java.security.KeyStore;

import javax.net.ssl.TrustManagerFactory;

/**
 * Created by swayangjit on 27/3/20.
 */
public class ApiServiceImpl implements ApiService{

    private static final String TAG = "SB-Sync-ApiServiceImpl";
    private TLSConfiguration tlsConfiguration;

    public ApiServiceImpl() {
        this.initializeTTLConfiguraion();
    }

    @Override
    public HttpResponse process(Request request) {
        HttpOperation httpOperation = new HttpOperation(request.getType(), request.getHost() + request.getPath(),
                request.getSerializer(), request.getBody(), request.getHeaders(), this.tlsConfiguration);
        return httpOperation.execute();
    }

    private void initializeTTLConfiguraion() {
        this.tlsConfiguration = new TLSConfiguration();

        try {
            KeyStore store = KeyStore.getInstance("AndroidCAStore");
            String tmfAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(tmfAlgorithm);

            store.load(null);
            tmf.init(store);

            this.tlsConfiguration.setHostnameVerifier(null);
            this.tlsConfiguration.setTrustManagers(tmf.getTrustManagers());
        } catch (Exception e) {
            Log.e(TAG, "An error occured while loading system's CA certificates", e);
        }
    }
}
