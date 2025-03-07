import SwiftUI
import Vision
import PhotosUI

struct VisionView: View {
    @State private var faceCount: Int = 0
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var detectionStatus: String = "이미지를 선택해주세요"
    @State private var isProcessing: Bool = false
    private let faceDetectionManager = FaceDetectionManager()

    var body: some View {
        VStack {
            Text("얼굴 인식")
                .font(.title)
                .padding()

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .cornerRadius(10)
            }

            PhotosPicker(selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                Text("사진 선택하기")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()

            if isProcessing {
                ProgressView("처리 중...")
                    .padding()
            } else {
                Text("감지된 얼굴: \(faceCount)개")
                    .font(.headline)
                    .padding()
                
                Text(detectionStatus)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                isProcessing = true
                detectionStatus = "이미지 로딩 중..."
                
                do {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)?.preparingForVisionProcessing() {
                        selectedImage = image
                        detectionStatus = "얼굴 인식 처리 중..."
                        detectFaces(in: image)
                    } else {
                        detectionStatus = "이미지 로딩 실패"
                        isProcessing = false
                    }
                } catch {
                    print("이미지 로딩 에러:", error.localizedDescription)
                    detectionStatus = "이미지 로딩 실패"
                    isProcessing = false
                }
            }
        }
        .onAppear {
            if selectedImage == nil {
                if let defaultImage = UIImage(named: "face") {
                    detectFaces(in: defaultImage)
                }
            }
        }
    }

    private func detectFaces(in image: UIImage) {
        faceDetectionManager.detectFaces(in: image) { faces in
            isProcessing = false
            faceCount = faces.count
            
            if faces.isEmpty {
                detectionStatus = "얼굴이 발견되지 않았습니다"
            } else {
                detectionStatus = "\(faces.count)개의 얼굴이 발견되었습니다"
            }
        }
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
