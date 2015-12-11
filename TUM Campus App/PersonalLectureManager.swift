//
//  PersonSearchManager.swift
//  TUM Campus App
//
//  Created by Mathias Quintero on 12/8/15.
//  Copyright © 2015 LS1 TUM. All rights reserved.
//

import Foundation
import Alamofire
import SWXMLHash

class PersonalLectureManager: Manager {
    
    static var lectures = [DataElement]()
    
    var main: TumDataManager?
    
    required init(mainManager: TumDataManager) {
        main = mainManager
    }
    
    func fetchData(handler: ([DataElement]) -> ()) {
        if !PersonalLectureManager.lectures.isEmpty {
            handler(PersonalLectureManager.lectures)
        } else {
            let url = getURL()
            Alamofire.request(.GET, url).responseString() { (response) in
                if let value = response.result.value {
                    let parsedXML = SWXMLHash.parse(value)
                    let rows = parsedXML["rowset"]["row"].all
                    for row in rows {
                        if let name = row["stp_sp_titel"].element?.text, id = row["stp_sp_nr"].element?.text, swsString = row["stp_sp_sst"].element?.text, lectureID = row["stp_lv_nr"].element?.text, sws = Int(swsString), semester = row["semester_name"].element?.text, chair = row["org_name_betreut"].element?.text, contributors = row["vortragende_mitwirkende"].element?.text, type = row["stp_lv_art_name"].element?.text {
                            let newLecture = Lecture(id: id, lectureID: lectureID, module: "", name: name, semester: semester, sws: sws, chair: chair, contributors: contributors, type: type)
                            PersonalLectureManager.lectures.append(newLecture)
                        }
                    }
                    handler(PersonalLectureManager.lectures)
                }
            }
        }
    }
    
    func getURL() -> String {
        let base = TUMOnlineWebServices.BaseUrl.rawValue + TUMOnlineWebServices.PersonalLectures.rawValue
        if let token = main?.getToken() {
            let url = base + "?" + TUMOnlineWebServices.TokenParameter.rawValue + "=" + token
            return url;
        }
        return ""
    }
    
}