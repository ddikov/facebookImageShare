//
//  ViewController.swift
//  Facebook Share
//
//  Created by Dobromir Dikov on 3/23/16.
//  Copyright © 2016 Brother Lemon. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKShareKit

class ViewController: UIViewController {
    
    let imgurAPIkey = "YOUR API KEY"
    
    let imgurAPIurl = "https://api.imgur.com/3/image"

    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func postButtonAction(sender: AnyObject) {
        
        postImage("Title", description: "Description", image: imageView.image!)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Methods
    
    func postImage(title:String, description:String, image:UIImage) {
        
        //First we will get the URL from the provided String by using GUARD, to ensure that we won't attempt to proceed with a wrong URL.
        guard let url = NSURL(string: imgurAPIurl) else {
            print("Error: cannot create URL")
            return
        }
        
        //Create url request to send to Imgur
        let urlRequest = NSMutableURLRequest(URL: url)
        urlRequest.HTTPMethod = "POST"
        
        //Convert the passed image from UIImage to NSData
        let imageData: NSData = UIImageJPEGRepresentation(image, 1.0)!
        
        //The following part builds up the message that we will send to Imgur, I pretty much copied that part from a ObjC tutorial
        let requestBody: NSMutableData = NSMutableData()
        let boundary: String = "---------------------------0983745982375409872438752038475287"
        let contentType: String = "multipart/form-data; boundary=\(boundary)"
        urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
        // Add client ID as authrorization header
        urlRequest.addValue("Client-ID \(imgurAPIkey)", forHTTPHeaderField: "Authorization")
        // Image File Data
        requestBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData("Content-Disposition: attachment; name=\"image\"; filename=\".tiff\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBody.appendData(NSData(data: imageData))
        requestBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        // Title parameter
        if title != "" {
            requestBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            requestBody.appendData(String(format: "Content-Disposition: form-data; name=\"title\"\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            requestBody.appendData(title.dataUsingEncoding(NSUTF8StringEncoding)!)
            requestBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        // Description parameter
        if description != "" {
            requestBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            requestBody.appendData(String(format: "Content-Disposition: form-data; name=\"description\"\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            requestBody.appendData(description.dataUsingEncoding(NSUTF8StringEncoding)!)
            requestBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        requestBody.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        urlRequest.HTTPBody = requestBody
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: config)
        
        //Create the task that will submit the request
        let task = session.dataTaskWithRequest(urlRequest) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            //response handler - work with the returned data, please note this operation is performed asynchronously
            if let httpResponse = response as? NSHTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
                if (statusCode == 200) { //As per Imgur API docs this status code means all is OK
                    print("Everyone is fine, file downloaded successfully.")
                    
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        
                        if let dataForFB = json["data"] {
                            //We need the link, but if you print(json) you will see all the goodies that are available in the returned data
                            if let urlForFB = dataForFB!["link"] {
                                
                                //print the URL to check if it's OK
                                print(urlForFB!)
                                
                                self.postImage(title, description: description, link: urlForFB as! String)
                                
                            }
                            if let deleteHash = dataForFB!["deletehash"] {
                                //The delete hash can be passed to the same url used for upload and it will delete the image, not needed for our purposes right now but good to know.
                                print(deleteHash!)
                            }
                        }
                        
                    } catch {
                        print("error serializing JSON: \(error)")
                    }
                } else {
                    print("Status code: \(statusCode)")
                }
            }
            
        }
        
        task.resume()
    }
    
    
    func postImage(title:String, description:String, link:String) {

        //First we create a NSURL from the link provided as a String
        let url = NSURL(string: link)
        
        //Then we generate a facebook Share Photo object from the url and indicate that it was generated by the user
        let ph = FBSDKSharePhoto(imageURL: url!, userGenerated: true)
        
        //These properties you will get via the Get Code menu in facebook app dashboard (where you set up your Action, Object and Custom Story)
        let properties: [NSObject : AnyObject] = ["og:type": "lemonquotes:quote", "og:title": title, "og:description": description]
        
        //Create the Open Graph object
        let object: FBSDKShareOpenGraphObject = FBSDKShareOpenGraphObject(properties: properties)
        
        //Create the action itself
        let action: FBSDKShareOpenGraphAction = FBSDKShareOpenGraphAction()
        
        //This comes from the same Get Code menu, but when you select to get the code for the action
        action.actionType = "lemonquotes:share"
        action.setObject(object, forKey: "lemonquotes:quote")
        
        //Set the image as an Array, as here you can actually post more than one image
        action.setArray([ph], forKey: "image")
        
        //Create the content and add the action to it
        let content: FBSDKShareOpenGraphContent = FBSDKShareOpenGraphContent()
        content.action = action
        content.previewPropertyName = "lemonquotes:quote"
        
        //Execute the Share Dialog
        FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: nil)
        
    }
    
    
}

