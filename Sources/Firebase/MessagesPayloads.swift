//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/30/23.
//

import Foundation

/*
 type Notification struct {
     Title    string `json:"title,omitempty"`
     Body     string `json:"body,omitempty"`
     ImageURL string `json:"image,omitempty"`
 }
 */
public struct FcmNotification: Codable {
      public let title: String?
      public let body: String?
      public let imageURL: String?

      enum CodingKeys: String, CodingKey {
          case title
          case body
          case imageURL = "image"
      }

      init(
          title: String? = nil,
          body: String? = nil,
          imageURL: String? = nil
      ) {
          self.title = title
          self.body = body
          self.imageURL = imageURL
      }
  }
  
  /*
 // AndroidConfig contains messaging options specific to the Android platform.
 type AndroidConfig struct {
     CollapseKey           string               `json:"collapse_key,omitempty"`
     Priority              string               `json:"priority,omitempty"` // one of "normal" or "high"
     TTL                   *time.Duration       `json:"-"`
     RestrictedPackageName string               `json:"restricted_package_name,omitempty"`
     Data                  map[string]string    `json:"data,omitempty"` // if specified, overrides the Data field on Message type
     Notification          *AndroidNotification `json:"notification,omitempty"`
     FCMOptions            *AndroidFCMOptions   `json:"fcm_options,omitempty"`
 }
 */
public struct AndroidConfig: Codable {
    public let collapseKey: String?
    public let priority: String?
    //    public let ttl: Double?
    public let restrictedPackageName: String?
    public let data: [String: String]?
    public let notification: AndroidNotification?
    //    public let fcmOptions: AndroidFCMOptions?
    
    enum CodingKeys: String, CodingKey {
        case collapseKey = "collapse_key"
        case priority
        case restrictedPackageName = "restricted_package_name"
        case data
        case notification
        //        case fcmOptions = "fcm_options"
    }
    
    init(
        collapseKey: String? = nil,
        priority: String? = nil,
        restrictedPackageName: String? = nil,
        data: [String: String]? = nil,
        notification: AndroidNotification? = nil
    ) {
        self.collapseKey = collapseKey
        self.priority = priority
        self.restrictedPackageName = restrictedPackageName
        self.data = data
        self.notification = notification
    }
}

/*
 
 // AndroidNotification is a notification to send to Android devices.
 type AndroidNotification struct {
     Title                 string                        `json:"title,omitempty"` // if specified, overrides the Title field of the Notification type
     Body                  string                        `json:"body,omitempty"`  // if specified, overrides the Body field of the Notification type
     Icon                  string                        `json:"icon,omitempty"`
     Color                 string                        `json:"color,omitempty"` // notification color in #RRGGBB format
     Sound                 string                        `json:"sound,omitempty"`
     Tag                   string                        `json:"tag,omitempty"`
     ClickAction           string                        `json:"click_action,omitempty"`
     BodyLocKey            string                        `json:"body_loc_key,omitempty"`
     BodyLocArgs           []string                      `json:"body_loc_args,omitempty"`
     TitleLocKey           string                        `json:"title_loc_key,omitempty"`
     TitleLocArgs          []string                      `json:"title_loc_args,omitempty"`
     ChannelID             string                        `json:"channel_id,omitempty"`
     ImageURL              string                        `json:"image,omitempty"`
     Ticker                string                        `json:"ticker,omitempty"`
     Sticky                bool                          `json:"sticky,omitempty"`
     EventTimestamp        *time.Time                    `json:"-"`
     LocalOnly             bool                          `json:"local_only,omitempty"`
     Priority              AndroidNotificationPriority   `json:"-"`
     VibrateTimingMillis   []int64                       `json:"-"`
     DefaultVibrateTimings bool                          `json:"default_vibrate_timings,omitempty"`
     DefaultSound          bool                          `json:"default_sound,omitempty"`
     LightSettings         *LightSettings                `json:"light_settings,omitempty"`
     DefaultLightSettings  bool                          `json:"default_light_settings,omitempty"`
     Visibility            AndroidNotificationVisibility `json:"-"`
     NotificationCount     *int                          `json:"notification_count,omitempty"`
 }
*/

public struct AndroidNotification: Codable {
    public var ClickAction: String
    
    enum CodingKeys: String, CodingKey {
        case ClickAction = "click_action"
    }
    
}
 
 /*
 type WebpushFCMOptions struct {
     Link string `json:"link,omitempty"`
 }
 */

struct WebpushFCMOptions: Codable {
    public let link: String?

    enum CodingKeys: String, CodingKey {
        case link
    }

    init(link: String? = nil) {
        self.link = link
    }
}


/*
 // FCMOptions contains additional options to use across all platforms.
 type FCMOptions struct {
     AnalyticsLabel string `json:"analytics_label,omitempty"`
 }
 */
public struct FCMOptions: Codable {
    public let analyticsLabel: String?

    enum CodingKeys: String, CodingKey {
        case analyticsLabel = "analytics_label"
    }

    init(analyticsLabel: String? = nil) {
        self.analyticsLabel = analyticsLabel
    }
}


/* TODO
 type APNSPayload struct {
     Aps        *Aps                   `json:"aps,omitempty"`
     CustomData map[string]interface{} `json:"-"`
 }
 */


/*
 type APNSConfig struct {
     Headers    map[string]string `json:"headers,omitempty"`
     Payload    *APNSPayload      `json:"payload,omitempty"`
     FCMOptions *APNSFCMOptions   `json:"fcm_options,omitempty"`
 }
 */
//struct APNSConfig: Codable {
//    public let headers: [String: String]?
//    public let payload: APNSPayload?
//    public let fcmOptions: APNSFCMOptions?
//
//    enum CodingKeys: String, CodingKey {
//        case headers
//        case payload
//        case fcmOptions = "fcm_options"
//    }
//
//    init(
//        headers: [String: String]? = nil,
//        payload: APNSPayload? = nil,
//        fcmOptions: APNSFCMOptions? = nil
//    ) {
//        self.headers = headers
//        self.payload = payload
//        self.fcmOptions = fcmOptions
//    }
//}

/*
 type Message struct {
     Data         map[string]string `json:"data,omitempty"`
     Notification *Notification     `json:"notification,omitempty"`
     Android      *AndroidConfig    `json:"android,omitempty"`
     Webpush      *WebpushConfig    `json:"webpush,omitempty"`
     APNS         *APNSConfig       `json:"apns,omitempty"`
     FCMOptions   *FCMOptions       `json:"fcm_options,omitempty"`
     Token        string            `json:"token,omitempty"`
     Topic        string            `json:"-"`
     Condition    string            `json:"condition,omitempty"`
 }
 */
public struct Message: Codable {
    public let data: [String: String]?
    public let notification: FcmNotification?
    public let android: AndroidConfig?
//    public let webpush: WebpushConfig?
//    public let apns: APNSConfig?
    public let fcmOptions: FCMOptions?
    public let token: String?
    public let topic: String?
    public let condition: String?

    enum CodingKeys: String, CodingKey {
        case data
        case notification
        case android
//        case webpush
//        case apns
        case fcmOptions = "fcm_options"
        case token
        case topic
        case condition
    }

    init(
        data: [String: String]? = nil,
        notification: FcmNotification? = nil,
        android: AndroidConfig? = nil,
//        webpush: WebpushConfig? = nil,
//        apns: APNSConfig? = nil,
        fcmOptions: FCMOptions? = nil,
        token: String? = nil,
        topic: String? = nil,
        condition: String? = nil
    ) {
        self.data = data
        self.notification = notification
        self.android = android
//        self.webpush = webpush
//        self.apns = apns
        self.fcmOptions = fcmOptions
        self.token = token
        self.topic = topic
        self.condition = condition
    }
}

public struct SendResponse: Codable {
    public var success: Bool
    public var messageID: String
    public var error: String? // Assuming error is represented by its message. Adjust if needed.

    private enum CodingKeys: String, CodingKey {
        case success
        case messageID = "messageID"
        case error
    }
}


public struct FcmRequest: Codable {
    public var validateOnly: Bool
    public var message: Message

    private enum CodingKeys: String, CodingKey {
        case validateOnly = "validateOnly"
        case message = "message"
    }
}

//
//type fcmRequest struct {
//    ValidateOnly bool     `json:"validate_only,omitempty"`
//    Message      *Message `json:"message,omitempty"`
//}
