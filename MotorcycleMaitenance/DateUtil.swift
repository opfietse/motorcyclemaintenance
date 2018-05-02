//
//  DateUtil.swift
//  MotorcycleMaitenance
//
//  Created by Mark on 24/04/2018.
//  Copyright © 2018 Mark Reuvekamp. All rights reserved.
//

import Foundation

public class DateUtil {
    static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd-MM-yyyy"
        return f
    }
    
    init() {
        DateUtil.dateFormatter.dateFormat = "dd-MM-yyyy"
    }

    static func formatDate(date: Date) -> String {
        return DateUtil.dateFormatter.string(from: date)
    }
    
    static func dateFromString(dateAsString: String) -> Date {
        let formatter = DateUtil.dateFormatter
        let dateFormConst = formatter.date(from: "23-09-2018")
        return DateUtil.dateFormatter.date(from: dateAsString)!
    }
}
