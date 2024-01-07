//
//  ContentView.swift
//  PetLinkerProject
//
//  Created by Minseok Shim on 2023-12-24.
//

import SwiftUI
import Foundation
import CoreData

class PersistenceController {
  static let shared = PersistenceController()
  let container: NSPersistentContainer
  init() {
      container = NSPersistentContainer(name: "DataModel")
      container.loadPersistentStores { (storeDescription, error) in
          if let error = error as NSError? {
              fatalError("Error: \(error), \(error.userInfo)")
          }
      }
  }
}

class PetViewModel: ObservableObject {
    @Published var selectedPet: Pet?
    @Published var pets: [Pet] = []
    @Published var selectedCategory = 0
    
    let categories = ["Dog", "Cat", "Bird"]

    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
        fetchPets()
    }

    func fetchPets() {
        let request: NSFetchRequest<Pet> = Pet.fetchRequest()
        do {
            pets = try container.viewContext.fetch(request)
        } catch {
            print("Error fetching pets: \(error)")
        }
    }

    func addPet(name: String, gender: String, age: String, breed: String, image: UIImage, descr: String) {
        let category = categories[selectedCategory]
        let newPet = Pet(context: container.viewContext)
        newPet.name = name
        newPet.gender = gender
        newPet.age = age
        newPet.breed = breed
        newPet.category = category
        newPet.image = image.jpegData(compressionQuality: 1.0)
        newPet.descr = descr
        saveContext()
    }

    func updatePet(_ pet: Pet, name: String, gender: String, age: String, breed: String, image: UIImage, descr: String) {
        let category = categories[selectedCategory]
        pet.name = name
        pet.gender = gender
        pet.age = age
        pet.breed = breed
        pet.category = category
        pet.image = image.jpegData(compressionQuality: 1.0)
        pet.descr = descr
        saveContext()
    }
    
    func deletePet(_ pet: Pet) {
        container.viewContext.delete(pet)
        saveContext()
    }

    private func saveContext() {
        do {
            try container.viewContext.save()
            fetchPets()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

struct RadioButton: View {
    @Binding var selectedOption: Int
    let id: Int
    let text: String

    var body: some View {
        Button(action: {
            self.selectedOption = self.id
        }) {
            HStack {
                Circle()
                    .stroke(selectedOption == id ? Color.blue : Color.gray, lineWidth: 2)
                    .background(selectedOption == id ? Color.blue : Color.clear)
                    .clipShape(Circle())
                    .frame(width: 20, height: 20)
                Text(text)
                    .font(.body)
                    .foregroundColor(.black)
                Spacer()
            }
        }
    }
}

struct RadioButtonGroup: View {
    @Binding var selectedOption: Int
    let items: [String]

    var body: some View {
        VStack {
            ForEach(0..<items.count) { index in
                RadioButton(selectedOption: $selectedOption, id: index, text: self.items[index])
            }
        }
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}

struct AnimalPicker: View {

    @Binding var selectedIndex: Int

    var body: some View {
        Picker(selection: $selectedIndex, label: Text("Select a pet type")) {
            Text("Dogs").tag(0)
            Text("Cats").tag(1)
            Text("Birds").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct ContentView: View {
    @StateObject var viewModel: PetViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to PetLinker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Image("Pets_Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                NavigationLink(destination: PetListView().environmentObject(viewModel)) {
                    Text("Continue")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
struct PetListView: View {
    @EnvironmentObject var viewModel: PetViewModel
    @State private var isShowingNewPetForm = false

    var body: some View {
        ScrollView {
            VStack {
                AnimalPicker(selectedIndex: $viewModel.selectedCategory)
                ForEach(viewModel.pets.filter { viewModel.categories[viewModel.selectedCategory] == $0.category }, id: \.self) { pet in
                    PetCard(pet: pet)
                }
                NavigationLink(destination: PetFormView().environmentObject(viewModel), isActive: $isShowingNewPetForm) { EmptyView() }

                Button("Add New Pet") {
                    isShowingNewPetForm = true
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding()
                .navigationTitle("Pet Types")
            }
        }
    }
}

struct PetCard: View {
    @EnvironmentObject var viewModel: PetViewModel
    var pet: Pet

    var body: some View {
        NavigationLink(destination: PetDetailView(pet: pet).environmentObject(viewModel)) {
            VStack {
                if let data = pet.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 200)
                }
                Text(pet.name ?? "Unknown")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .shadow(radius: 10)
        }
    }
}

struct PetFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: PetViewModel

    @State private var name: String = ""
    @State private var gender: String = ""
    @State private var age: String = ""
    @State private var breed: String = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var descr: String = ""

    var pet: Pet?

    init(pet: Pet? = nil) {
        self.pet = pet
        _name = State(initialValue: pet?.name ?? "")
        _gender = State(initialValue: pet?.gender ?? "")
        _age = State(initialValue: pet?.age ?? "")
        _breed = State(initialValue: pet?.breed ?? "")
        _descr = State(initialValue: pet?.descr ?? "")
        if let data = pet?.image, let image = UIImage(data: data) {
            _inputImage = State(initialValue: image)
        }
    }

    var body: some View {
            VStack {
                Button("Select Image") { showingImagePicker = true }
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                }
                CustomTextField(placeholder: "Name", text: $name)
                CustomTextField(placeholder: "Gender", text: $gender)
                CustomTextField(placeholder: "Age", text: $age)
                CustomTextField(placeholder: "Breed", text: $breed)

                TextEditor(text: $descr)
                    .frame(height: 200)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )

                Button(action: {
                    if let inputImage = inputImage {
                        if let pet = pet {
                            viewModel.updatePet(pet, name: name, gender: gender, age: age, breed: breed, image: inputImage, descr: descr)
                        } else {
                            viewModel.addPet(name: name, gender: gender, age: age, breed: breed, image: inputImage, descr: descr)
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                }
            }
            .navigationBarTitle(pet == nil ? "New Pet" : "Edit Pet", displayMode: .inline)
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
        }

    func loadImage() {
       
    }
}

struct PetDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: PetViewModel
    var pet: Pet

    var body: some View {
        VStack {
            if let data = pet.image, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
            }
            VStack(alignment: .leading) {
                Text("Name: ") + Text(pet.name ?? "").bold()
                Text("Gender: ") + Text(pet.gender ?? "").bold()
                Text("Age: ") + Text(pet.age ?? "").bold()
                Text("Breed: ") + Text(pet.breed ?? "").bold()
                Text("Category: ") + Text(pet.category ?? "").bold()
                Text("Description: \n") + Text(pet.descr ?? "").bold()
            }
            NavigationLink(destination: PetFormView(pet: pet).environmentObject(viewModel)) {
                Text("Edit")
            }
            Button(action: {
                viewModel.deletePet(pet)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Delete")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle("Pet Details")
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
