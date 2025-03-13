import SwiftUI
import Vision
import PhotosUI

struct VisionView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var detectedFaces: [VNFaceObservation] = []
    @State private var identifiedPeople: [String: [UIImage]] = [:]
    @State private var isProcessing = false
    @State private var showingNameInput = false
    @State private var newPersonName = ""
    @State private var selectedFace: VNFaceObservation?
    @State private var processingProgress: Double = 0
    
    private let faceRecognition = FaceRecognition.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if isProcessing {
                    ProgressView(value: processingProgress) {
                        Text("사진 처리 중... \(Int(processingProgress * 100))%")
                    }
                    .padding()
                }
                
                List {
                    ForEach(Array(identifiedPeople.keys.sorted()), id: \.self) { name in
                        Section(header: Text(name)) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(identifiedPeople[name] ?? [], id: \.self) { image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                PhotosPicker(selection: $selectedItems,
                           maxSelectionCount: 10,
                           matching: .images,
                           photoLibrary: .shared()) {
                    Text("사진 선택 (최대 10장)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("얼굴 인식")
            .alert("새로운 인물 등록", isPresented: $showingNameInput) {
                TextField("이름", text: $newPersonName)
                Button("취소", role: .cancel) { }
                Button("저장") {
                    if let face = selectedFace, !newPersonName.isEmpty {
                        faceRecognition.addFace(face, forPerson: newPersonName)
                        if identifiedPeople[newPersonName] == nil {
                            identifiedPeople[newPersonName] = []
                        }
                        if let image = selectedImages.first {
                            identifiedPeople[newPersonName]?.append(image)
                        }
                        newPersonName = ""
                    }
                }
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    isProcessing = true
                    processingProgress = 0
                    selectedImages.removeAll()
                    
                    for (index, item) in newItems.enumerated() {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                            await processImage(image)
                            processingProgress = Double(index + 1) / Double(newItems.count)
                        }
                    }
                    
                    isProcessing = false
                }
            }
        }
    }
    
    private func processImage(_ image: UIImage) async {
        await withCheckedContinuation { continuation in
            faceRecognition.detectFaces(in: image) { faces in
                for face in faces {
                    let features = faceRecognition.extractFaceFeatures(from: face)
                    if let name = faceRecognition.identifyPerson(faceFeatures: features) {
                        if identifiedPeople[name] == nil {
                            identifiedPeople[name] = []
                        }
                        identifiedPeople[name]?.append(image)
                    }
                }
                continuation.resume()
            }
        }
    }
}

struct FaceBox: View {
    let face: VNFaceObservation
    let size: CGSize
    
    var body: some View {
        let rect = CGRect(
            x: face.boundingBox.origin.x * size.width,
            y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * size.height,
            width: face.boundingBox.width * size.width,
            height: face.boundingBox.height * size.height
        )
        
        return Rectangle()
            .stroke(Color.green, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}

extension UIImage {
    func preparingForVisionProcessing() -> UIImage? {
        // 이미지 크기가 너무 크면 리사이징
        let maxDimension: CGFloat = 1024
        let size = self.size
        
        if size.width > maxDimension || size.height > maxDimension {
            let ratio = size.width / size.height
            let newSize: CGSize
            
            if ratio > 1 {
                newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
            } else {
                newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
            }
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage
        }
        
        return self
    }
}
