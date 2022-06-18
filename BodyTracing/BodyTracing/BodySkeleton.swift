//
//  BodySkeleton.swift
//  BodyTracing
//
//  Created by Snow Lukin on 18.06.2022.
//

import SwiftUI
import RealityKit
import ARKit

class BodySkeleton: Entity {
    
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]
    
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            var jointRadius: Float = 0.05
            var jointColor: UIColor = .green
            
            // Setting color and size bazed ob specific jointName
            // Green joints - tracked by ARKit
            // Yellow joints - not tracked
            
            switch jointName {
            case "neck_1_joint", "neck_2_joint", "neck_3_joint",
                "neck_4 _joint", "head joint",
                "left_shoulder_1_joint", "right_shoulder_1_joint":
                jointRadius *= 0.5
            case "jaw_joint", "chin_joint",
                "left_eye_joint",
                "left_eyeLowerLid_joint",
                "left_eyeUpperLid_joint",
                "left_eyeball_joint", "nose_joint",
                "right_eye_joint",
                "right_eyeLowerLid_joint",
                "right_eyeUpperLid_joint", "right_eyeball_joint":
                jointRadius *= 0.2
                jointColor = .yellow
            case _ where jointName.hasPrefix("spine_"):
                jointRadius *= 0.75
            case "left_hand_joint", "right_hand_joint":
                jointRadius *= 1
                jointColor = .green
            case _ where jointName.hasPrefix("left_hand") || jointName.hasPrefix("right_hand"):
                jointRadius *= 0.25
                jointColor = .yellow
            case _ where jointName.hasPrefix("left_toes") || jointName.hasPrefix("right_toes"):
                jointRadius *= 0.5
                jointColor = .yellow
            default:
                jointRadius = 0.05
                jointColor = .green
            }
            
            // Create an entity for joint
            let jointEntity = createJoint(radius: jointRadius, color: jointColor)
            // Add it to joints dict
            joints[jointName] = jointEntity
            // Add to parent entity (body Skeleton)
            self.addChild(jointEntity)
        }
        
        for bone in Bones.allCases {
            guard let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor) else {
                continue
            }
            // Create an entity for the bone
            let boneEntity = createBoneEntity(for: skeletonBone)
            // Add to bone dict
            bones[bone.name] = boneEntity
            // Add to parent entity (bodySkeleton)
            self.addChild(boneEntity)
        }
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    private func createJoint(radius: Float, color: UIColor = .white) -> Entity {
        // Create a sphere entity for every single joint of the skeleton
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        return entity
    }
    
    // Construct a skeleton bone given a bone and body anchor
    private func createSkeletonBone(bone: Bones, bodyAnchor: ARBodyAnchor) -> SkeletonBone? {
        guard let fromJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointFromName)) else { return nil }
        guard let toJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointToName)) else { return nil }
        
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        // position relative to root
        let jointFromEntityOffsetFromRoot = simd_make_float3(fromJointEntityTransform.columns.3)
        // position in world
        let jointFromPosition = jointFromEntityOffsetFromRoot + rootPosition
        
        // position relative to root
        let jointToEntityOffsetFromRoot = simd_make_float3(toJointEntityTransform.columns.3)
        // position in world
        let jointToPosition = jointToEntityOffsetFromRoot + rootPosition
        
        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: jointFromPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: jointToPosition)
        
        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }
    
    private func createBoneEntity(for skeletonBone: SkeletonBone, diameter: Float = 0.04, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateBox(size: [diameter, diameter, skeletonBone.length], cornerRadius: diameter / 2)
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        return entity
    }
}
