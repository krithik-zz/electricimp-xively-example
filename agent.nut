/*
The MIT License (MIT)

Copyright (c) 2013 Electric Imp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

Xively <- {};    // this makes a 'namespace'

class Xively.Client {
    ApiKey = null;
    triggers = null;

	constructor(apiKey) {
		this.ApiKey = apiKey;
        this.triggers = [];
	}
	
	/*****************************************
	 * method: PUT
	 * IN:
	 *   feed: a XivelyFeed we are pushing to
	 *   ApiKey: Your Xively API Key
	 * OUT:
	 *   HttpResponse object from Xively
	 *   200 and no body is success
	 *****************************************/
	function Put(feed){
		local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
		local request = http.put(url, headers, feed.ToJson());

		return request.sendsync();
	}
    	function PutLocation(location){
		local url = "https://api.xively.com/v2/feeds/" + location.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
		local request = http.put(url, headers, location.ToJson());

		return request.sendsync();
	}	
	/*****************************************
	 * method: GET
	 * IN:
	 *   feed: a XivelyFeed we are pulling from
	 *   ApiKey: Your Xively API Key
	 * OUT:
	 *   An updated XivelyFeed object on success
	 *   null on failure
	 *****************************************/
	function Get(feed){
		local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "User-Agent" : "xively-Imp-Lib/1.0" };
		local request = http.get(url, headers);
		local response = request.sendsync();
		if(response.statuscode != 200) {
			server.log("error sending message: " + response.body);
			return null;
		}
	
		local channel = http.jsondecode(response.body);
		for (local i = 0; i < channel.datastreams.len(); i++)
		{
			for (local j = 0; j < feed.Channels.len(); j++)
			{
				if (channel.datastreams[i].id == feed.Channels[j].id)
				{
					feed.Channels[j].current_value = channel.datastreams[i].current_value;
					break;
				}
			}
		}
	
		return feed;
	}

}
    

class Xively.Feed{
    FeedID = null;
    Channels = null;
    
    constructor(feedID, channels)
    {
        this.FeedID = feedID;
        this.Channels = channels;
    }
    
    function GetFeedID() { return FeedID; }

    function ToJson()
    {
        local json = "{ \"datastreams\": [";
        for (local i = 0; i < this.Channels.len(); i++)
        {
            json += this.Channels[i].ToJson();
            if (i < this.Channels.len() - 1) json += ",";
        }
        json += "] }";
        return json;
    }
}
class Xively.Location {
    FeedID = null;
    disposition = null;
    name = null;
    exposure = null;
    domain = null;
    ele = null;
    lat = null;
    lon = null;
    
    constructor(feedID)
    {
        this.FeedID = feedID;
    }
    function GetFeedID() { return FeedID; }
    
    function Set(disposition, name, exposure, domain, ele, lat, lon) {
        this.disposition = disposition;
        this.name = name;
        this.exposure = exposure;
        this.domain = domain;
        this.ele = ele;
        this.lat = lat;
        this.lon = lon;
    }
    function ToJson() { 
        local json = http.jsonencode({ "location": {disposition = this.disposition, name = this.name,
        exposure = this.exposure, domain = this.domain, ele = this.ele, lat = this.lat, lon = this.lon}});
        return json;
    }
}
class Xively.Channel {
    id = null;
    current_value = null;
    mytag = "";
    
    constructor(_id)
    {
        this.id = _id;
    }
    
    function Set(value, tag) { 
    	this.current_value = value;
        this.mytag = tag;
    }
    
    function Get() { 
    	return this.current_value; 
    }
    
    function ToJson() { 
    	return http.jsonencode({id = this.id, current_value = this.current_value }); 
    }
}

/***************************************************** END OF API CODE *****************************************************/

 
// create the Xively channel , API Key comes from Xively
client <- Xively.Client("insert_your_api_key_here");

// create a channel and assign a value
signalChannel <- Xively.Channel("signalStrength");

// create a feed, feedID comes from Xively
feed <- Xively.Feed("insert_your_feedD_here", [signalChannel]);

//when device is sending 'rssi'
device.on("rssi", function(rssiValue) {       
   
    //set new rssi value, to the rssi 'tag'
    signalChannel.Set(rssiValue, "rssi");
    
    //update Xively
    client.Put(feed);
});





