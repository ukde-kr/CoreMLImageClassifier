import SwiftUI
import CoreML
import Vision

struct ContentView: View {
    @State private var image: UIImage? = nil
    @State private var classificationLabel: String = "이미지를 선택하세요!"
    @State private var showImagePicker = false  // ✅ 사진 선택 Sheet 상태 변수 추가

    var body: some View {
        VStack {
            Text("이미지 분류기")
                .font(.largeTitle)
                .padding()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .cornerRadius(12)
            }

            Text(classificationLabel)
                .font(.headline)
                .padding()

            Button("사진 선택하기") {
                showImagePicker = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image)
                .onDisappear {
                    if let selectedImage = image {
                        classifyImage(selectedImage)
                    }
                }
        }
    }

    // MARK: - 이미지 분류 함수
    func classifyImage(_ uiImage: UIImage) {
        guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
            classificationLabel = "모델 로드 실패"
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                classificationLabel = "분류 실패"
                return
            }

            DispatchQueue.main.async {
                classificationLabel = "결과: \(topResult.identifier) (\(Int(topResult.confidence * 100))%)"
            }
        }

        guard let ciImage = CIImage(image: uiImage) else { return }
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? handler.perform([request])
    }
}
