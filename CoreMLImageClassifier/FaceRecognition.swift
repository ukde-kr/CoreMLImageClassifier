import Vision
import UIKit

class FaceDetectionManager {
    func detectFaces(in image: UIImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let results = request.results as? [VNFaceObservation], error == nil else {
                print("Face detection error:", error?.localizedDescription ?? "Unknown error")
                completion([])
                return
            }
            completion(results) // 얼굴 인식 결과 반환
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform face detection:", error.localizedDescription)
                completion([])
            }
        }
    }
}
