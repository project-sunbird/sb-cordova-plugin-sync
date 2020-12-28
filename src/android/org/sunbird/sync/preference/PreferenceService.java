package org.sunbird.sync.preference;

/**
 * Created by swayangjit on 9/6/20.
 */

public interface PreferenceService {

    String getBearerToken();

    String getUserToken();

    String getManagedUserToken();

    String getTraceId();

    void setTraceId(String traceId);
}
