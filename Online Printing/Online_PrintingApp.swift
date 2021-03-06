//
//  Online_PrintingApp.swift
//  Online Printing
//
//  Created by Karen Mirakyan on 26.09.20.
//

import SwiftUI
import IdramMerchantPayment

@main
struct Online_PrintingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var mainVM = MainViewModel()
    @ObservedObject var authVM = AuthViewModel()
    
    
    init() {
        let newAppearance = UINavigationBarAppearance()
        newAppearance.configureWithOpaqueBackground()
        newAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black, .font: UIFont( name: "McLaren-Regular", size: 20)!]
        UINavigationBar.appearance().standardAppearance = newAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.mainVM)
                .environmentObject(self.authVM)
                .onOpenURL(perform: { (url) in
                    
                    print(url)
                    
                    if let urlComponents = URLComponents(string: url.absoluteString), let _ = urlComponents.host, let queryItems = urlComponents.queryItems {

                        if let errorCode = queryItems[0].value {
                            if errorCode == "0" {
                                self.mainVM.placeOrder()
                            } else {
                                self.mainVM.activeAlert = .error
                                self.mainVM.alertMessage = "Sorry something went wrong"
                                self.mainVM.showAlert.toggle()
                            }
                        }
                    }

                })
        }
    }
}
