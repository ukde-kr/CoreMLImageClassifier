import Vision
import UIKit

class FaceRecognition {
    static let shared = FaceRecognition()
    
    private var knownFaces: [String: [VNFaceObservation]] = [:]
    private var currentRequest: VNDetectFaceRectanglesRequest?
    private var currentHandler: VNImageRequestHandler?
    
    func detectFaces(in image: UIImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        // 이전 요청이 있다면 취소
        currentRequest?.cancel()
        currentHandler = nil
        
        guard let cgImage = image.cgImage else {
            print("CGImage 변환 실패")
            completion([])
            return
        }
        
        // 이미지 방향 보정
        let imageOrientation = CGImagePropertyOrientation(image.imageOrientation)
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("얼굴 인식 에러: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation] else {
                print("얼굴 인식 결과 변환 실패")
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // 현재 요청이 유효한지 확인
            guard self.currentRequest === request else {
                print("이전 요청이 취소되었습니다")
                return
            }
            
            DispatchQueue.main.async {
                print("감지된 얼굴 수: \(observations.count)")
                completion(observations)
            }
        }
        
        // Vision 요청 설정
        request.preferBackgroundProcessing = true
        request.usesCPUOnly = true
        
        // 현재 요청 저장
        currentRequest = request
        
        // Vision 이미지 처리 핸들러 설정
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: imageOrientation,
            options: [:]
        )
        
        // 현재 핸들러 저장
        currentHandler = handler
        
        // 백그라운드에서 Vision 처리 실행
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let currentRequest = self.currentRequest,
                  handler === self.currentHandler else {
                print("요청이 취소되었거나 새로운 요청이 시작되었습니다")
                return
            }
            
            do {
                try handler.perform([currentRequest])
            } catch {
                print("얼굴 인식 수행 실패: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    func extractFaceFeatures(from observation: VNFaceObservation) -> [Float] {
        // 얼굴의 주요 특징점 추출
        var features: [Float] = []
        
        // 얼굴의 바운딩 박스 정보
        let bbox = observation.boundingBox
        features.append(contentsOf: [
            Float(bbox.origin.x),
            Float(bbox.origin.y),
            Float(bbox.width),
            Float(bbox.height)
        ])
        
        // 얼굴의 방향 정보
        if let yaw = observation.yaw {
            features.append(yaw.floatValue)
        }
        if let roll = observation.roll {
            features.append(roll.floatValue)
        }
        
        return features
    }
    
    func compareFaces(_ face1: [Float], _ face2: [Float]) -> Float {
        guard face1.count == face2.count else { return 0 }
        
        var similarity: Float = 0
        for i in 0..<face1.count {
            let diff = face1[i] - face2[i]
            similarity += 1 - abs(diff)
        }
        
        return similarity / Float(face1.count)
    }
    
    func identifyPerson(faceFeatures: [Float], threshold: Float = 0.8) -> String? {
        for (name, faces) in knownFaces {
            for face in faces {
                let features = extractFaceFeatures(from: face)
                let similarity = compareFaces(faceFeatures, features)
                
                if similarity >= threshold {
                    return name
                }
            }
        }
        return nil
    }
    
    func addFace(_ observation: VNFaceObservation, forPerson name: String) {
        if knownFaces[name] == nil {
            knownFaces[name] = []
        }
        knownFaces[name]?.append(observation)
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
