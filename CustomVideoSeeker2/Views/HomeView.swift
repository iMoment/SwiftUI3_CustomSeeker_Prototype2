//
//  HomeView.swift
//  CustomVideoSeeker2
//
//  Created by Stanley Pan on 2022/02/23.
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @State var currentCoverImage: UIImage?
    @State var progress: CGFloat = 0
    
    var body: some View {
        VStack {
            
            VStack {
                
                HStack {
                    
                    Button {
                        
                    } label: {
                        
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        
                    }
                }
                .overlay {
                    Text("Cover")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding([.horizontal, .bottom])
                .padding(.top, 10)
                
                Divider()
                    .background(Color.black.opacity(0.6))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            // MARK: Current Cover Image
            GeometryReader { proxy in
                let size = proxy.size
                
                ZStack {
                    if let currentCoverImage = currentCoverImage {
                        Image(uiImage: currentCoverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .cornerRadius(15)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: size.width, height: size.height)
            }
            .frame(width: 200, height: 300)
            
            Text("To select a cover image, choose one from\nyour video or an image from your camera roll.")
                .font(.caption)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.vertical, 30)
            
            // MARK: Cover Image Scroller
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: "IMG_2730", ofType: "MOV") ?? "")
            VideoCoverScroller(videoURL: url, progress: $progress)
                .padding(.top, 50)
                .padding(.horizontal, 15)
            
            Button {
                // TODO: Action for button
            } label: {
                Label {
                    Text("Add From Camera Roll")
                } icon: {
                    Image(systemName: "plus.square")
                        .font(.title2)
                }
                .foregroundColor(.primary)
            }
            .padding(.vertical)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

// MARK: Custom Cover Image Scroller

struct VideoCoverScroller: View {
    var videoURL: URL
    @Binding var progress: CGFloat
    @State var imageSequence: [UIImage]?
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            HStack(spacing: 0) {
                // MARK: Image sequence
                if let imageSequence = imageSequence {
                    ForEach(imageSequence, id: \.self) { index in
                        GeometryReader { proxy in
                            let subSize = proxy.size
                            
                            Image(uiImage: index)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: subSize.width, height: subSize.height)
                        }
                        .frame(height: size.height)
                    }
                }
            }
            .cornerRadius(6)
            .onAppear {
                generateImageSequence(size: size)
            }
        }
        .frame(height: 50)
    }
    
    func generateImageSequence(size: CGSize) {
        // Split duration into 10-second intervals
        let parts = (videoDuration() / 10)
        
        (0..<10).forEach { index in
            // Retrieve cover image
            // Converting Index to progress with respect to duration
            let progress = (CGFloat(index) * parts) / videoDuration()
            
            retrieveCoverImageAt(progress: progress, size: size) { image in
                // Check for image being nil
                if imageSequence == nil { imageSequence = [] }
                imageSequence?.append(image)
            }
        }
    }
    
    func retrieveCoverImageAt(progress: CGFloat, size: CGSize, completion: @escaping (UIImage) -> ()) {
        DispatchQueue.global(qos: .userInteractive).async {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = size
            
            let time = CMTime(seconds: progress * videoDuration(), preferredTimescale: 600)
            
            do {
                let image = try generator.copyCGImage(at: time, actualTime: nil)
                let cover = UIImage(cgImage: image)
                
                DispatchQueue.main.async {
                    completion(cover)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // Retrieving video duration
    func videoDuration() -> Double {
        let asset = AVAsset(url: videoURL)
        
        return asset.duration.seconds
    }
}
