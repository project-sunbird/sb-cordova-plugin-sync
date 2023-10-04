package org.sunbird.sync.model;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by swayangjit on 25/3/20.
 */
public class NetworkQueueModel implements Comparable<NetworkQueueModel>{
    private String msgId;
    private String type;
    private Integer priority;
    private Integer eventCount;
    private Long timestamp;
    private Request request;
    private String config;

    public NetworkQueueModel(String msgId, String type, Integer priority, Long timestamp, String config, Integer eventCount, Request request) {
        this.msgId = msgId;
        this.type = type;
        this.priority = priority;
        this.timestamp = timestamp;
        this.request = request;
        this.config = config;
        this.eventCount = eventCount;
    }

    public String getId() {
        return msgId;
    }

    public String getType() {
        return type;
    }

    public Integer getPriority() {
        return priority;
    }

    public Long getTimestamp() {
        return timestamp;
    }

    public Request getRequest() {
        return request;
    }

    public Integer getEventCount() {
        return eventCount;
    }

    public JSONObject getConfig() throws JSONException {
        if(config != null){
            return new JSONObject(config);
        }
        return null;
    }

    @Override
    public int compareTo(NetworkQueueModel networkQueueModel) {
        int currentFailedSyncCount = this.getRequest().getNoOfFailureSync();
        int failedSyncCount = networkQueueModel.getRequest().getNoOfFailureSync();

        int currentPriority = this.getPriority() + currentFailedSyncCount;
        int priority = networkQueueModel.getPriority() + failedSyncCount;

        if (priority < currentPriority) {
            return 1;
        } else if (priority > currentPriority) {
            return -1;
        }

        return 0;
    }

    @Override
    public String toString() {
        return "NetworkQueueModel{" +
                "msgId='" + msgId + '\'' +
                '}';
    }
}
