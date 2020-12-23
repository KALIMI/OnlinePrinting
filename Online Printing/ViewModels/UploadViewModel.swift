//
//  UploadViewModel.swift
//  Online Printing
//
//  Created by Karen Mirakyan on 20.11.20.
//

import Foundation

class UploadViewModel : ObservableObject {
    
    // Order Details
    @Published var info: String = ""
    @Published var count: String = ""
    @Published var size: String = ""
    @Published var sizePrice: String = ""
    @Published var fileName: String = ""
    @Published var address: String = ""
    @Published var path: URL? = nil
    @Published var selectedCategory: CategoryModel? = nil
    @Published var orderList = [CartItemModel]()
    
    // Alert
    @Published var activeAlert: ActiveAlert? = nil
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    // Loading
    @Published var loading: Bool = false

    
    func placeOrder() {
        self.loading = true
        UploadService().uploadFileToStorage(cartItems: self.orderList, completion: { (response) in
            if let response = response {
                UploadService().placeOrder(orderList: self.orderList, address: self.address, fileURLS: response) { (orderPlacementResponse) in
                    if orderPlacementResponse == true {
                        self.orderList.removeAll(keepingCapacity: false)
                        self.loading = false
                        self.activeAlert = .placeCompleted
                        self.alertMessage = "Շնորհավորում ենք Ձեր պատվերը գրանցված է:"
                        self.showAlert = true
                    } else {
                        
                        self.loading = false
                        self.activeAlert = .error
                        self.alertMessage = "Ցավոք տեղի է ունեցել սխալ"
                        self.showAlert = true
                    }
                }
            }
        })
    }
}
