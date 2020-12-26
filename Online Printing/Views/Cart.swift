//
//  Checkout.swift
//  Online Printing
//
//  Created by Karen Mirakyan on 08.12.20.
//

import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI
import IdramMerchantPayment

struct Cart: View {
    
    @EnvironmentObject var uploadVM: UploadViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var paymentVM = PaymentViewModel()
    
    var body: some View {
        
        VStack {
            
            List {
                ForEach( self.uploadVM.orderList, id: \.id ) { order in
                    
                    HStack {
                        WebImage(url: URL(string: order.image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        VStack( alignment: .leading) {
                            Text( "Category: \(order.category)" )
                            Text( "Dimensions: \(order.dimensions)" )
                            Text( "Count: \(order.count)" )
                            Text( "Total Price: \(order.totalPrice)" )
                        }
                    }.padding( .horizontal, 8 )
                }.onDelete(perform: delete)
            }
            
            Button(action: {
                if Auth.auth().currentUser == nil {
                    self.authVM.showAuth.toggle()
                } else if self.uploadVM.orderList.isEmpty {
                    self.uploadVM.activeAlert = .error
                    self.uploadVM.alertMessage = "Զամբյուղը դատարկ է:"
                    self.uploadVM.showAlert = true
                } else {
//                    self.dialog()
                    self.paymentVM.calculateTotalAmount(products: self.uploadVM.orderList)
                    self.paymentVM.payWithIdram()
                }
            }, label: {
                Text( "Գրանցել Պատվեր" )
                    .foregroundColor(Color.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)
            }).padding(.bottom, 10)
        }.sheet(isPresented: self.$authVM.showAuth, content: {
            AuthView()
                .environmentObject(self.authVM)
        })
    }
    
    func delete(at offsets: IndexSet) {
        self.uploadVM.orderList.remove(atOffsets: offsets)
    }
    
    func dialog(){
        
        let alertController = UIAlertController(title: "Address", message: "Մուտքագրեք հասցեն:", preferredStyle: .alert)
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Մուտքագրեք հասցեն"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
        
        
        let saveAction = UIAlertAction(title: "Done", style: .default, handler: { alert -> Void in
            
            let secondTextField = alertController.textFields![0] as UITextField
            if secondTextField.text == "" {
                self.uploadVM.activeAlert = .error
                self.uploadVM.alertMessage = "Մուտքագրեք հասցեն"
                self.uploadVM.showAlert = true
            } else {
                
                self.uploadVM.address = secondTextField.text ?? "Invalid Address"
                uploadVM.placeOrder()
            }
        })
        
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

struct Checkout_Previews: PreviewProvider {
    static var previews: some View {
        Cart()
    }
}
