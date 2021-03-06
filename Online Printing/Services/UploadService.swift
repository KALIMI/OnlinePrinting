//
//  UploadService.swift
//  Online Printing
//
//  Created by Karen Mirakyan on 20.11.20.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseAuth
import Combine
import CombineFirebaseFirestore

protocol UploadServiceProtocol {
    func uploadFileToStorage( cartItems: [CartItemModel], completion: @escaping ( [String]? ) -> () )
    func placeOrder( orderList: [CartItemModel], address: String, fileURLS: [String], paymentMethod: String, completion: @escaping ( Bool ) -> ())
    func calculateAmount( selectedCategorySpecs: Specs, count: Int, typeOfPrinting: String, additionalFunctionalityTitle: String, completion: @escaping ( Int ) -> () )
    func storeLastVisitedCategory( category: CategoryModel, completion: @escaping ( Data?) -> ())
}


class UploadService {
    static let shared: UploadServiceProtocol = UploadService()
    
    private init() { }
}

extension UploadService : UploadServiceProtocol{
    
    func uploadFileToStorage( cartItems: [CartItemModel], completion: @escaping ( [String]? ) -> () ) {
        let storageRef = Storage.storage().reference()
        let mediaFolder = storageRef.child("uploaded")
        
        var fileURLS = [(String, Int)]()
        
        for (index, item) in cartItems.enumerated() {
            
            let fileRef = mediaFolder.child("\(UUID().uuidString).pdf")
            
            fileRef.putFile(from: item.filePath, metadata: nil) { (metadata, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        completion( nil )
                    }
                    return
                }
                
                fileRef.downloadURL { (url, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            completion( nil )
                        }
                        return
                    }
                    
                    fileURLS.append(( url?.absoluteString ?? "", index))
                    
                    if fileURLS.count == cartItems.count {
                        DispatchQueue.main.async {
                            completion( fileURLS.sorted(by: { $0.1 < $1.1 }).map { tuple in tuple.0 } )
                        }
                    }
                }
            }
        }
    }
    
    func placeOrder( orderList: [CartItemModel], address: String, fileURLS: [String], paymentMethod: String, completion: @escaping ( Bool ) -> () ) {
        let db = Firestore.firestore()
        
        var orders = [[String: Any]]()
        var totalPrice = 0
        
        for i in 0..<orderList.count {
            totalPrice += orderList[i].totalPrice
            
            orders.append([
                "productName" : orderList[i].category,
                "dimensions" : orderList[i].dimensions,
                "count" : orderList[i].count,
                "price" : orderList[i].totalPrice,
                "file" : fileURLS[i],
                "additionalInformation" : orderList[i].info,
                "additionalFunctionality": orderList[i].additionalFunctionality,
                "typeOfPrinting": orderList[i].oneSide_Color_bothSide_ColorPrinting
            ])
        }
        
        let orderDetails = [
            "totalPrice" : totalPrice,
            "address" : address,
            "paymentMethod": paymentMethod
        ] as [String : Any]
        
        db.collection("Orders").document(Auth.auth().currentUser!.phoneNumber!).collection("orders").addDocument( data: [ "orderDetails" : orderDetails, "order" : orders ]) { (error) in
            if error != nil {
                DispatchQueue.main.async {
                    completion( false )
                }
                return
            }
            
            DispatchQueue.main.async {
                completion( true )
            }
        }
        
    }
    
    func calculateAmount(selectedCategorySpecs: Specs, count: Int, typeOfPrinting: String, additionalFunctionalityTitle: String, completion: @escaping (Int) -> ()) {
        
        var pricePerUnit: Int
        var amount: Int = 0
        var additionalFunctionality: AdditionalFunctionality?
        
        // search additionalFunctionality in selectedCategorySpecs by title
        for searchAdditionalFunctionality in selectedCategorySpecs.additionalFunctionality {
            if additionalFunctionalityTitle == searchAdditionalFunctionality.functionalityTitle {
                additionalFunctionality = searchAdditionalFunctionality
            }
        }
        
        if typeOfPrinting == "One Side" || typeOfPrinting == "OneColor" { pricePerUnit = selectedCategorySpecs.oneSide_ColorPrice }
        else                                                            { pricePerUnit = selectedCategorySpecs.bothSide_ColorPrice }
        
        if 0...selectedCategorySpecs.minCount ~= count {
            amount = count * pricePerUnit + ( additionalFunctionality == nil ? 0 : count * additionalFunctionality!.functionalityAdditionalPrice )
        } else if selectedCategorySpecs.minCount...selectedCategorySpecs.maxCount ~= count {
            amount = count * pricePerUnit - count * selectedCategorySpecs.minCountDiscount + ( additionalFunctionality == nil ? 0 : count * additionalFunctionality!.functionalityAdditionalPrice )
        } else {
            amount = count * pricePerUnit - count * selectedCategorySpecs.maxCountDiscount + ( additionalFunctionality == nil ? 0 : count * additionalFunctionality!.functionalityAdditionalPrice )
        }
        
        DispatchQueue.main.async {
            completion( amount )
        }
    }
    
    func storeLastVisitedCategory( category: CategoryModel, completion: @escaping ( Data?) -> ()) {
        URLSession.shared.dataTask(with: URL(string: category.image)!) { data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    completion( nil )
                }
                return
            }
            
            if let data = data {
                let widgetModel = WidgetModel(image: data, title: category.name)

                guard let categoryData = try? JSONEncoder().encode(widgetModel) else {
                    return
                }
                
                DispatchQueue.main.async {
                    completion( categoryData )
                }
            }
        }.resume()
    }
}
