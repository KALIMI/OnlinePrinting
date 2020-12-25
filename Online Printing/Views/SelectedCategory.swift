//
//  SelectedCategory.swift
//  Online Printing
//
//  Created by Karen Mirakyan on 09.10.20.
//

import SwiftUI
import AlertX

struct SelectedCategory: View {
    
    @EnvironmentObject var uploadVM: UploadViewModel
    
    let category: CategoryModel
    @State private var openFile: Bool = false
    
    var body: some View {
        
        
        VStack( spacing: 20) {
            
            SizeScroller(category: self.category).environmentObject( self.uploadVM )
            
            TextField("Նշեք քանակը", text: self.$uploadVM.count)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .shadow(color: Color.gray, radius: 8, x: 8, y: 8)
            
            
            TextField("Հավելյալ Նշումներ", text: self.$uploadVM.info)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .shadow(color: Color.gray, radius: 8, x: 8, y: 8)
            
            
            Button {
                
                self.openFile.toggle()
                
            } label: {
                
                if self.uploadVM.fileName == "" {
                    VStack {
                        Image("upload")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                        
                        Text( "Ներբեռնել ֆայլը" )
                    }
                } else {
                    Text( self.uploadVM.fileName )
                }
                
            }
            
            Button {
                if self.uploadVM.size == "" || self.uploadVM.count == "" || self.uploadVM.fileName == "" {
                    self.uploadVM.activeAlert = .error
                    self.uploadVM.alertMessage = "Լրացրեք բոլոր անհրաժեշտ դաշտերը:"
                    self.uploadVM.showAlert = true
                } else {
                    self.uploadVM.activeAlert = .dialog
                    self.uploadVM.alertMessage = "\(UploadService().countPrice(count: Int( self.uploadVM.count )!, price: Int( self.uploadVM.sizePrice )!))"
                    self.uploadVM.selectedCategory = self.category
                    self.uploadVM.showAlert = true
                }
            } label: {
                
                Text( "Հաշվարկել Գումարը" )
                    .foregroundColor(Color.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)
            }
            
            Spacer()
            
        }.padding()
        .fileImporter(isPresented: self.$openFile, allowedContentTypes: [.pdf], onCompletion: { (res) in
            do {
                
                let fileURL = try res.get()
                self.uploadVM.fileName = fileURL.lastPathComponent
                
                saveFile(url: fileURL)
                
            } catch {
                print(error.localizedDescription)
            }
        })
        .navigationBarTitle(Text(self.category.name), displayMode: .inline)
        
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    
    func saveFile (url: URL) {
        if (CFURLStartAccessingSecurityScopedResource(url as CFURL)) {
            
            let fileData = try? Data.init(contentsOf: url)
            let fileName = url.lastPathComponent
            
            let actualPath = getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                try fileData?.write(to: actualPath)
                if ( fileData == nil ) {
                    print("Permission error!")
                } else {
                    self.uploadVM.path = actualPath
                }
            } catch {
                print(error.localizedDescription)
            }
            CFURLStopAccessingSecurityScopedResource(url as CFURL)
        } else {
            print("Permission error!")
        }
    }
}

struct SizeScroller : View {
    
    let category: CategoryModel
    @EnvironmentObject var uploadVM: UploadViewModel
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach( self.category.dimensions, id : \.id) { dimension in
                    
                    Button {
                        self.uploadVM.size = dimension.size
                        self.uploadVM.sizePrice = dimension.price
                    } label: {
                        VStack {
                            Image("dimens")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .foregroundColor( self.uploadVM.size == dimension.size ? Color.black : Color.gray)
                            
                            Text( dimension.size )
                        }
                    }
                }
            }
        }
    }
}


