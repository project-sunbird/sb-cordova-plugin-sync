package org.sunbird.sync.network;

import org.sunbird.sync.model.HttpResponse;
import org.sunbird.sync.model.Request;

/**
 * Created by swayangjit on 29/3/20.
 */
public interface ApiService {

    HttpResponse process(Request request);
}
