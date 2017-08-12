

import UIKit
import AVKit
import AVFoundation
import GoogleCast

class ViewController: UIViewController, GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate, UIActionSheetDelegate, GCKSessionManagerListener {
    @IBOutlet weak var playerFrame: UIView!
    @IBOutlet weak var castButton: GCKUICastButton!
    
    var sessionManger: GCKSessionManager? = nil
    var castMediaController: GCKUIMediaController? = nil
    var castSession: GCKCastSession? = nil
    
    var url:URL? = nil
    

    enum PlaybackMode: Int {
        case none = 0
        case local
        case remote
    }
    
    var playbackMode:PlaybackMode = PlaybackMode.none
    
    
    var player = AVPlayer()
    let avpController = AVPlayerViewController()
    var timer: DispatchSourceTimer?
    
    var currentItem: AVPlayerItem!
    
    var playerDurationINT = 0
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // let url = URL(string: "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")
        //let url = URL(string: "https://ia800201.us.archive.org/12/items/BigBuckBunny_328/BigBuckBunny_512kb.mp4")
        
       // let url = URL(string:"http://engtestsite.com/bsdk/Chromecast%20Sender/")
        
        
        
        url = URL(string:"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
        player = AVPlayer(url: url!)
        
        avpController.player = player
        avpController.view.frame = playerFrame.frame
        self.addChildViewController(avpController)
        self.view.addSubview(avpController.view)
        
        currentItem = player.currentItem!
        
      //  player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        
        
        player.play()
        
        sessionManger = GCKCastContext.sharedInstance().sessionManager
        
        sessionManger?.add(self)
        
        
        
        GCKCastContext.sharedInstance().presentCastInstructionsViewControllerOnce()
        castMediaController = GCKUIMediaController.init()
        castSession = GCKCastSession.init()
        
        player.play()
        
        view.superview?.addSubview(self.castButton)
        
        
        let playerDuration = player.currentItem?.asset.duration
        
        playerDurationINT = Int(CMTimeGetSeconds(playerDuration!))
        
        
        // buildMediaInformation()
        // playSelectedItemRemotely()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        
//        GCKCastContext.sharedInstance().presentCastInstructionsViewControllerOnce()
//        castMediaController = GCKUIMediaController.init()
//        castSession = GCKCastSession.init()
//        
//        player.play()
//        
//        view.superview?.addSubview(self.castButton)
//        
//
//        let playerDuration = player.currentItem?.asset.duration
//        
//        playerDurationINT = Int(CMTimeGetSeconds(playerDuration!))
//        
//
//       // buildMediaInformation()
//       // playSelectedItemRemotely()

        
    }
    
    func buildMediaInformation() -> GCKMediaInformation {
       // let mediaInfo = GCKMediaInformation.init(contentID: "Big Buck Bunny", streamType: GCKMediaStreamType.buffered, contentType: "video/mp4", metadata: nil, streamDuration: TimeInterval(playerDurationINT), customData: nil)
        
        let mediaInfo = GCKMediaInformation.init(contentID: (url?.absoluteString)!, streamType: GCKMediaStreamType.buffered, contentType: "video/mp4", metadata: nil, streamDuration: TimeInterval(playerDurationINT), customData: nil)
        
        return mediaInfo
    }
    

    
    func playSelectedItemRemotely() {
        let castSession = GCKCastContext.sharedInstance().sessionManager.currentSession
        if ((castSession) != nil) {
            castSession?.remoteMediaClient?.loadMedia(self.buildMediaInformation(), autoplay: true)
        } else {
            print("no castSession!")
        }
    }
    
    
//MARK: - Playback functions
    
    func switchToLocalPlayback() {
        if (playbackMode == PlaybackMode.local) {
            return
        }
        
        var playPosition: TimeInterval = 0
        var paused = false
        var ended = false
        
        if (playbackMode == PlaybackMode.remote) {
            playPosition = (castMediaController?.lastKnownStreamPosition)!
            paused = castMediaController?.lastKnownPlayerState == GCKMediaPlayerState.paused
            ended = castMediaController?.lastKnownPlayerState == GCKMediaPlayerState.idle
            print("last player state: \(String(describing: castMediaController?.lastKnownPlayerState)):, ended: \(ended)")
        }
        castSession?.remoteMediaClient?.remove(self as! GCKRemoteMediaClientListener)
        castSession = nil
        
        playbackMode = PlaybackMode.local
    }
    
    
    
    func switchToRemotePlayback() {
        if (playbackMode == PlaybackMode.remote) {
            return
        }
        
        castSession = sessionManger?.currentCastSession
        
        var playPosition = TimeInterval((player.currentItem?.currentTime().seconds)!)
        var paused = player.rate == 0
        
        var builder = GCKMediaQueueItemBuilder.init()
        builder.mediaInformation = buildMediaInformation()
        builder.autoplay = !paused
        builder.preloadTime = 3
        
        var item = builder.build()
        
        castSession?.remoteMediaClient?.queueLoad([item], start: 0, playPosition: playPosition, repeatMode: GCKMediaRepeatMode.off, customData: nil)
        
        player.pause()
        playbackMode = PlaybackMode.remote
        
    }
    

    
//    - (BOOL)continueAfterPlayButtonClicked {
//    NSLog(@"continueAfterPlayButtonClicked");
//    BOOL hasConnectedCastSession =
//    [GCKCastContext sharedInstance].sessionManager.hasConnectedCastSession;
//    if (self.mediaInfo && hasConnectedCastSession) {
//    [self playSelectedItemRemotely];
//    return NO;
//    }
//    return YES;
//    }
//    
//    
    func continueAfterPlayButtonClicked() -> Bool {
        var hasConnectedCastSession = GCKCastContext.sharedInstance().sessionManager.hasConnectedSession()
        
        playSelectedItemRemotely()
        return true
    }
    

//MARK: - Session Manager functions
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("MediaView Controller: sessionManager didStartSession \(session)")
        switchToRemotePlayback()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        print("MediaViewController: sessionManager didResumeSession \(session)")
        switchToRemotePlayback()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print("session ended with error: \(String(describing: error))")
        switchToLocalPlayback()
    }
    
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        
    }
    
    
//MARK: - Chromecast functions
    
    

    
    
//MARK: - Cloud Leftovers
    
    
    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if player.rate > 0.0 {
//            if (isFirstTime == true) {
//                sessionID = String(Int(NSTimeIntervalSince1970)*Int(arc4random()/332))
//                isFirstTime = false
//            }
//            
//            //Set total length
//            let duration : CMTime = player.currentItem!.asset.duration
//            let seconds = String(Int(CMTimeGetSeconds(duration)))
//            length = seconds
//            
//            isComplete = false
//            startTimer()
//        }
//        
//        if player.rate < 1.0 {
//            timer?.cancel()
//            
//            var playhead = self.getTime()
//            NielsenCloud(Cloud_Event: "playhead", Playhead_Time: playhead, Content_Type: "content")
//            
//            if(playhead == length) {
//                NielsenCloud(Cloud_Event: "complete", Playhead_Time: playhead, Content_Type: "content")
//                isComplete = true
//            }
//        }
//    }
    
//    func startTimer() {
//        let queue = DispatchQueue(label: "com.firm.app.timer", attributes: .concurrent)
//        
//        timer?.cancel()        // cancel previous timer if any
//        
//        timer = DispatchSource.makeTimerSource(queue: queue)
//        
//        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(10), leeway: .milliseconds(100))
//        
//        timer?.setEventHandler {  // `[weak self]` only needed if you reference `self` in this closure and you want to prevent strong reference cycle
//            
//            NielsenCloud(Cloud_Event: "playhead", Playhead_Time: self.getTime(), Content_Type: "content")
//        }
//        
//        timer?.resume()
//    }
    
    
//    func getTime() -> String {
//        let t1 = Float(self.player.currentTime().value)
//        let t2 = Float(self.player.currentTime().timescale)
//        
//        return String(Int(t1 / t2))
//    }
    
    
    
//    @IBAction func exitPlayer(_ sender: UIButton) {
//        timer?.cancel()
//        if (isComplete == false) {
//            NielsenCloud(Cloud_Event: "playhead", Playhead_Time: self.getTime(), Content_Type: "content")
//        }
//        NielsenCloud(Cloud_Event: "delete", Playhead_Time: "", Content_Type: "content")
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    
    
}
