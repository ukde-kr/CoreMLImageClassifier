import SwiftUI
import Vision

struct VisionView: View {
    @State private var faceCount: Int = 0
    private let faceDetectionManager = FaceDetectionManager()

    var body: some View {
        VStack {
            Text("Face recognition")
                .font(.headline)

            Image("face")
                .resizable()
                .scaledToFit()
                .onAppear {
                    detectFaces()
                }

            Text("Detected faces: \(faceCount)")
                .font(.subheadline)
                .padding()
        }
    }

    /// 얼굴 인식 함수
    private func detectFaces() {
        guard let uiImage = UIImage(named: "face") else { return }
        faceDetectionManager.detectFaces(in: uiImage) { faces in
            DispatchQueue.main.async {
                self.faceCount = faces.count
            }
        }
    }
}
