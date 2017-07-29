/**
Copyright (c) 2017 Robert Scott Hanlon

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

import Foundation
import Alamofire
import ObjectMapper

class Networking {
    // MARK: Properties
    var sessionManager = SessionManager()
    
    // MARK: Typealias
    fileprivate typealias JSONFormat = [String: Any]
    
    /**
     Make a request using a URLRequestConvertible
     
     convertible: URLRequestConvertible for the request
     success: A closure for the success Mappable type response
     error: A closure for the error Mappable type response
     failure: API Request Failure which contains the localized description
     */
    func request<T: Mappable, E:Mappable>(convertible: URLRequestConvertible, success: @escaping (_ value: T) -> Void, error: @escaping (_ error: E) -> Void, failure: @escaping (_ error: String) -> Void) {
        sessionManager.request(convertible).responseJSON { (data) in
            switch data.result {
            case .success:
                if let value = data.result.value as? JSONFormat, let result = T(JSON: value), self.containsValues(object: result) {
                    success(result)
                } else if let value = data.result.value as? JSONFormat, let result = E(JSON: value), self.containsValues(object: result) {
                    error(result)
                }
            case .failure(let error):
                failure(error.localizedDescription)
            }
        }
    }
    
    /**
     Make a request using a URLRequestConvertible
     
     convertible: URLRequestConvertible for the request
     success: A closure for the success Array Mappable type response
     error: A closure for the error Mappable type response
     failure: API Request Failure which contains the localized description
     */
    func request<T: Mappable, E:Mappable>(convertible: URLRequestConvertible, success: @escaping (_ value: [T]) -> Void, error: @escaping (_ error: E) -> Void, failure: @escaping (_ error: String) -> Void) {
        sessionManager.request(convertible).responseJSON { (data) in
            switch data.result {
            case .success:
                if let value = data.result.value as? JSONFormat, let result = E(JSON: value), self.containsValues(object: result) {
                    error(result)
                } else if let value = data.result.value as? [JSONFormat], let result = Mapper<T>().mapArray(JSONArray: value) {
                    success(result)
                }
            case .failure(let error):
                failure(error.localizedDescription)
            }
        }
    }
    
    /**
     Check to see if this object contains any values
     
     object<Mappable>: The object to check
     
     returns: If this object contains any values
     */
    fileprivate func containsValues<T: Mappable>(object: T) -> Bool {
        var totalValues = 0
        var numNil = 0
        for child in Mirror(reflecting: object).children {
            totalValues += 1
            let mirror = Mirror(reflecting: child.value)
            if mirror.displayStyle == .optional, mirror.children.count == 0 {
                numNil += 1
            }
        }
        
        return totalValues != numNil
    }
}
