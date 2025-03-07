import Vision
import UIKit

class FaceDetectionManager {
    // Vision 요청 및 핸들러를 저장할 프로퍼티
    private var currentRequest: VNDetectFaceRectanglesRequest?
    private var currentHandler: VNImageRequestHandler?
    private var isProcessing: Bool = false
    
    // CIContext 인스턴스 생성 (재사용)
    private let ciContext = CIContext()
    
    func detectFaces(in image: UIImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        // 이전 요청이 진행 중이면 취소
        if isProcessing {
            print("이전 요청이 진행 중입니다. 취소 후 새로운 요청을 시작합니다.")
            currentRequest = nil
            currentHandler = nil
        }
        
        isProcessing = true
        
        // 1. 이미지 방향 보정
        let imageOrientation = CGImagePropertyOrientation(image.imageOrientation)
        
        // 2. CGImage 변환
        guard let cgImage = image.cgImage else {
            print("CGImage 변환 실패")
            isProcessing = false
            DispatchQueue.main.async { completion([]) }
            return
        }
        
        // 3. Vision 얼굴 인식 요청 생성
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            defer { self.isProcessing = false }
            
            // 에러 처리
            if let error = error {
                print("얼굴 인식 에러:", error.localizedDescription)
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // 결과 처리
            guard let observations = request.results as? [VNFaceObservation] else {
                print("얼굴 인식 결과를 변환하는데 실패했습니다.")
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // 현재 요청이 유효한지 확인
            guard self.currentRequest === request else {
                print("이전 요청이 취소되었습니다.")
                return
            }
            
            // 결과 전달
            DispatchQueue.main.async {
                print("감지된 얼굴 수:", observations.count)
                observations.forEach { face in
                    print("얼굴 위치: \(face.boundingBox)")
                }
                completion(observations)
            }
        }
        
        // 4. Vision 설정
        request.preferBackgroundProcessing = true
        request.usesCPUOnly = true  // GPU 관련 문제 방지
        
        // 5. 현재 요청 저장
        currentRequest = request
        
        // 6. Vision 이미지 처리 핸들러 설정
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        // 7. 현재 핸들러 저장
        currentHandler = handler
        
        // 8. 백그라운드에서 Vision 처리 실행
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let currentRequest = self.currentRequest,
                  handler === self.currentHandler else {
                print("요청이 취소되었거나 새로운 요청이 시작되었습니다.")
                self?.isProcessing = false
                return
            }
            
            do {
                try handler.perform([currentRequest])
            } catch {
                print("얼굴 인식 수행 실패:", error.localizedDescription)
                DispatchQueue.main.async { completion([]) }
                self.isProcessing = false
            }
        }
    }
}

// UIImage.Orientation을 CGImagePropertyOrientation으로 변환하는 확장
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
