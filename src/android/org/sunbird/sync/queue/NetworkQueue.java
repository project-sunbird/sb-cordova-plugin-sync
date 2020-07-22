package org.sunbird.sync.queue;

import org.sunbird.sync.model.NetworkQueueModel;

/**
 * Created by swayangjit on 26/3/20.
 */
public interface NetworkQueue {

    void seed();

    NetworkQueueModel dequeue(boolean isSoft);

    NetworkQueueModel peek();

    int getSize();

    boolean isEmpty();
    
}
