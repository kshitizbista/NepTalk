//
//  FirebaseStorage.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2021-12-19.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    private init() {}
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    public typealias UploadMediaCompletion = (Result<String, Error>) -> Void
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadMediaCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self] metaData, error in
            guard let self = self else {return}
            guard error == nil else {
                print("Failed to upload to firebase storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child(path).downloadURL { url, error in
            guard let url = url, error == nil  else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        }
    }   
    
    func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadMediaCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] metaData, error in
            guard let self = self else {return}
            guard error == nil else {
                print("Failed to upload to firebase storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    

    func uploadMessageVideo(with fileURL: URL, fileName: String, completion: @escaping UploadMediaCompletion) {
                
        guard let data = try? Data(contentsOf: fileURL) else {
            return
        }
        
        // TODO: use putFile instead of sending raw data as it take more memory when processing
        // https://stackoverflow.com/questions/58104572/cant-upload-video-to-firebase-storage-on-ios-13
        // https://stackoverflow.com/questions/38425154/using-firebase-storages-putfile-method-is-resulting-in-the-file-filename-c
        // https://stackoverflow.com/questions/56909566/video-upload-error-when-choosing-from-library
        // https://github.com/firebase/quickstart-ios/issues/1097
        
        storage.child("message_vidoes/\(fileName)").putData(data, metadata: nil) { [weak self] metaData, error in
            guard let self = self else {return}
            guard error == nil else {
                print("Failed to upload video file to firebase storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("message_vidoes/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download vidoe file url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
}
