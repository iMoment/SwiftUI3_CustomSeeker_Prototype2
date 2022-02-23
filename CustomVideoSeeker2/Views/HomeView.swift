//
//  HomeView.swift
//  CustomVideoSeeker2
//
//  Created by Stanley Pan on 2022/02/23.
//

import SwiftUI
import AVFoundation
import AVKit

struct HomeView: View {
    @State var currentCoverImage: UIImage?
    @State var progress: CGFloat = 0
    @State var url = URL(fileURLWithPath: Bundle.main.path(forResource: "IMG_2730", ofType: "MOV") ?? "")
    
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
                    // Custom video player will show preview
                    PreviewPlayer(url: url, progress: $progress)
                        .cornerRadius(15)
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

// MARK: Custom Video Player
struct PreviewPlayer: UIViewControllerRepresentable {
    var url: URL
    @Binding var progress: CGFloat
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        let duration = uiViewController.player?.currentItem?.duration.seconds ?? 0
        let time = CMTime(seconds: progress * duration, preferredTimescale: 600)
        uiViewController.player?.seek(to: time)
    }
}

// MARK: Custom Cover Image Scroller

struct VideoCoverScroller: View {
    var videoURL: URL
    @Binding var progress: CGFloat
    @State var imageSequence: [UIImage]?
    
    // MARK: Gesture Properties
    @State var offset: CGFloat = 0
    @GestureState var isDragging: Bool = false
    
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
            .overlay(alignment: .leading, content: {
                ZStack(alignment: .leading) {
                    Color.black
                        .opacity(0.25)
                    
                    PreviewPlayer(url: videoURL, progress: $progress)
                        .frame(width: 35, height: 60)
                        .cornerRadius(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white, lineWidth: 3)
                                .padding(-3)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.black.opacity(0.2))
                                .padding(-4)
                        )
                        .offset(x: offset)
                        .gesture(
                            DragGesture()
                                .updating($isDragging, body: { _, out, _ in
                                    out = true
                                })
                                .onChanged({ value in
                                    var translation = (isDragging ? value.location.x - 17.5 : 0)
                                    translation = (translation < 0 ? 0 : translation)
                                    translation = (translation > size.width - 35 ? size.width - 35 : translation)
                                    offset = translation
                                })
                        )
                }
            })
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
            
            retrieveCoverImageAt(progress: progress, size: CGSize(width: 100, height: 100)) { image in
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
