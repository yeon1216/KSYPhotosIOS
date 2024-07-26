//
//  EditMediaView.swift
//  KSYPhotos
//
//  Created by ksy on 7/15/24.
//

import SwiftUI
import ComposableArchitecture
import Mantis

@Reducer
struct EditMedia {
    struct State: Equatable {
        var media: KSYMedia
        var originalImg: UIImage? = nil
        var editThumbnail: UIImage? = nil
        var error: String? = nil
        var loading = false
        var showCropper = false
        var cropViewController: CropViewController? = nil
        var cropViewTransform: CropViewTransform? = nil
        var alpha: CGFloat = 1.0
        var showAdjustmentView = false
    }
    
    enum Action {
        case onAppear(KSYMedia)
        case fetchOriginalThumbnail(KSYMedia)
        case doneFetchOriginalThumbnail(TaskResult<GetThumbnailResDto>)
        case mediaItemTapped(KSYMedia)
        case closeIconTapped
        case saveIconTapped(UIImage, CGFloat)
        case doneSaveImage(TaskResult<SaveImageResDto>)
        case cropImg
        case applyCropImg(CropViewTransform, UIImage)
        case cancelCrop
        case cropBottomTabIconTapped
        case adjustmentBottomTabIconTapped
        case setCropViewController(CropViewController)
        case rotateRightIconTapped
        case rotateLeftIconTapped
        case leftRightFlipIconTapped
        case topDownFlipIconTapped
        case cancelAdjustment
        case changeAlpha(CGFloat)
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mediaService) var mediaService
    private enum CancelID { case fetchThumbnail, saveImage }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onAppear(ksyMedia):
                return .send(.fetchOriginalThumbnail(ksyMedia))
            case let .fetchOriginalThumbnail(ksyMedia):
                state.loading = true
                return .run { send in
                    await send(
                        .doneFetchOriginalThumbnail(
                            TaskResult { try await self.mediaService.getOriginalThumbnail(ksyMedia) }
                        )
                    )
                }
                .cancellable(id: CancelID.fetchThumbnail)
            case let .doneFetchOriginalThumbnail(.failure(error)):
                state.error = error.localizedDescription
                state.loading = false
                return .none
            case let .doneFetchOriginalThumbnail(.success(response)):
                state.loading = false
                if response.isPermission {
                    if response.thumbnail != nil {
                        state.originalImg = response.thumbnail
                        state.editThumbnail = response.thumbnail
                        state.media.isLocallyAvailable = true
                    }
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case .mediaItemTapped:
                return .none
            case .closeIconTapped:
                return .run { _ in
                    await self.dismiss()
                }
            case let .saveIconTapped(img, alpha):
                state.loading = true
                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                    if alpha != 1.0 {
                        await send(
                            .doneSaveImage(
                                TaskResult { try await self.mediaService.saveImage(img.withAlpha(alpha) ?? img) }
                            )
                        )
                    } else {
                        await send(
                            .doneSaveImage(
                                TaskResult { try await self.mediaService.saveImage(img) }
                            )
                        )
                    }
                    
                }
                .cancellable(id: CancelID.saveImage)
            case let .doneSaveImage(.failure(error)):
                state.error = error.localizedDescription
                state.loading = false
                return .none
            case let .doneSaveImage(.success(response)):
                state.loading = false
                if response.isPermission {
                    if response.success {
                        // TODO: 사진 저장 성공 다이얼로그
                    } else {
                        // TODO: 사진 저장 실패 다이얼로그
                    }
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case let .applyCropImg(cropViewTransform, img):
                state.cropViewTransform = cropViewTransform
                state.editThumbnail = img
                state.showCropper = false
                return .none
            case .cropImg:
                state.cropViewController?.crop()
                return .none
            case .cancelCrop:
                state.showCropper = false
                state.cropViewController = nil
                return .none
            case .cropBottomTabIconTapped:
                state.showCropper = true
                return .none
            case .adjustmentBottomTabIconTapped:
                state.showAdjustmentView = true
                return .none
            case let .setCropViewController(controller):
                state.cropViewController = controller
                return .none
            case .rotateRightIconTapped:
                state.cropViewController?.didSelectClockwiseRotate()
                return .none
            case .rotateLeftIconTapped:
                state.cropViewController?.didSelectCounterClockwiseRotate()
                return .none
            case .leftRightFlipIconTapped:
                state.cropViewController?.didSelectHorizontallyFlip()
                return .none
            case .topDownFlipIconTapped:
                state.cropViewController?.didSelectVerticallyFlip()
                return .none
            case .cancelAdjustment:
                state.showAdjustmentView = false
                return .none
            case let .changeAlpha(v):
                state.alpha = v
                return .none
            }
        }
    }
    
    
    
}

struct EditMediaView: View {
    
    let store: StoreOf<EditMedia>
    @State private var appeared = false
    let bottomTabItemCount: CGFloat = 2.0
    let cropBottomTabItemCount: CGFloat = 4.0
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                Color.nenioBlack.ignoresSafeArea()
                content
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                guard !appeared else { return }
                appeared = true
                viewStore.send(.onAppear(viewStore.media))
            }
        }
    }
    
    var topBar: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                ZStack(alignment: .center) {
                    HStack(spacing: 0) {
                        ZStack {
                            Image(systemName: "xmark")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color.gray200)
                                .frame(width: 18, height: 18)
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.closeIconTapped)
                        }
                        Spacer()
                    }
                    if viewStore.editThumbnail != nil {
                        HStack(spacing: 0) {
                            Spacer()
                            ZStack {
                                Text("저장")
                                    .buttonRegular(Color.purple200)
                            }
                            .frame(width: 56, height: 56)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewStore.send(.saveIconTapped(viewStore.editThumbnail!, viewStore.alpha))
                            }
                        }
                    }
                    
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                Divider()
            }
            .background(Color.gray900.opacity(0.4))
        }
    }
    
    var cropTopBar: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                ZStack(alignment: .center) {
                    HStack(spacing: 0) {
                        ZStack {
                            Text("취소")
                                .buttonRegular(Color.purple200)
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.cancelCrop)
                        }
                        Spacer()
                    }
                    if viewStore.editThumbnail != nil {
                        HStack(spacing: 0) {
                            Spacer()
                            ZStack {
                                Text("크롭")
                                    .buttonRegular(Color.purple200)
                            }
                            .frame(width: 56, height: 56)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewStore.send(.cropImg)
                            }
                        }
                    }
                    
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                Divider()
            }
            .background(Color.gray900.opacity(0.8))
        }
    }
    
    var adjustmentTopBar: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                ZStack(alignment: .center) {
                    HStack(spacing: 0) {
                        ZStack {
                            Text("취소")
                                .buttonRegular(Color.purple200)
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.cancelAdjustment)
                        }
                        Spacer()
                    }
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                Divider()
            }
            .background(Color.gray900.opacity(0.8))
        }
    }
    
    var adjustmentBottomView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 0) {
                    Spacer().frame(width: 24)
                    Text("알파")
                        .buttonRegular(Color.nenioWhite)
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                KSYSeekBar(
                    value: viewStore.binding(get: \.alpha, send: { .changeAlpha($0) }),
                    bounds: 0.0...1.0,
                    setValue: { v, changed in }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.gray900.opacity(0.4))
        }
    }
    
    
    
    
    
    var bottomTab: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            GeometryReader { geo in
                let geoW = geo.size.width
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 0) {
                        bottomTabItemView(
                            icon: "crop",
                            label: "크롭"
                        )
                        .frame(width: (geoW - 32) / bottomTabItemCount)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.cropBottomTabIconTapped)
                        }
                        bottomTabItemView(
                            icon: "plusminus.circle",
                            label: "조정"
                        )
                        .frame(width: (geoW - 32) / bottomTabItemCount)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.adjustmentBottomTabIconTapped)
                        }
                    }
                    .frame(height: 56)
                    .padding(.horizontal, 16)
                }
                .background(Color.gray900.opacity(0.4))
            }
            .frame(height: 56)
        }
    }
    
    var cropBottomTab: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            GeometryReader { geo in
                let geoW = geo.size.width
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 0) {
                        bottomTabItemView(
                            icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                            label: "좌우반전"
                        )
                        .frame(width: (geoW - 32) / cropBottomTabItemCount)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.leftRightFlipIconTapped)
                        }
                        bottomTabItemView(
                            icon: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                            label: "상하반전"
                        )
                        .frame(width: (geoW - 32) / cropBottomTabItemCount)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.topDownFlipIconTapped)
                        }
                        bottomTabItemView(
                            icon: "rotate.left",
                            label: "-90°"
                        )
                        .frame(width: (geoW - 32) / cropBottomTabItemCount)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.rotateRightIconTapped)
                        }
                        bottomTabItemView(
                            icon: "rotate.right",
                            label: "90°"
                        )
                        .frame(width: (geoW - 32) / cropBottomTabItemCount)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.rotateLeftIconTapped)
                        }
                    }
                    .frame(height: 56)
                    .padding(.horizontal, 16)
                }
                .background(Color.gray900.opacity(0.8))
            }
            .frame(height: 56)
        }
    }
    
    func getCropperTransformation(cropViewTransform: CropViewTransform?) -> Transformation? {
        if let trans = cropViewTransform {
            let cropTransform = Transformation(offset: trans.offset, rotation: trans.rotation, scale: trans.scale, manualZoomed: trans.manualZoomed, initialMaskFrame: trans.initialMaskFrame, maskFrame: trans.maskFrame, cropWorkbenchViewBounds: trans.cropWorkbenchViewBounds)
            return cropTransform
        }
        return nil
    }
    
    var content: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                Color.clear.ignoresSafeArea(.all)
                VStack(spacing: 0) {
                    if viewStore.showCropper {
                        cropTopBar
                    } else if viewStore.showAdjustmentView {
                        adjustmentTopBar
                    } else {
                        topBar
                    }
                    Spacer(minLength: 0)
                    if viewStore.loading {
                        loadingView
                    } else {
                        ZStack {
                            if viewStore.editThumbnail == nil {
                                Image(systemName: "photo")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray600)
                            }
                            if viewStore.editThumbnail != nil {
                                Image(uiImage: viewStore.editThumbnail!)
                                    .resizable()
                                    .renderingMode(.original)
                                    .aspectRatio(contentMode: .fit)
                                    .opacity(viewStore.alpha)
                            }
                            if viewStore.showCropper && viewStore.originalImg != nil {
                                ImageCropper(
                                    image: viewStore.originalImg!,
                                    transformation: self.getCropperTransformation(cropViewTransform: viewStore.cropViewTransform),
                                    didCrop: { cropViewTransfrom, croppedImg in
                                        viewStore.send(.applyCropImg(cropViewTransfrom, croppedImg))
                                    },
                                    cancelCrop: { _ in },
                                    getCropViewController: { cropViewController in
                                        viewStore.send(.setCropViewController(cropViewController))
                                    }
                                )
                            }
                        }
                        .overlay(content: {
                            if !viewStore.media.isLocallyAvailable {
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        ZStack {
                                            Image(systemName: "icloud.fill")
                                                .resizable()
                                                .renderingMode(.template)
                                                .foregroundColor(.gray600)
                                                .frame(width: 24, height: 24)
                                        }
                                        .frame(width: 44, height: 44)
                                    }
                                    Spacer()
                                }
                            }
                        })
                    }
                    Spacer(minLength: 0)
                    if viewStore.showCropper {
                        cropBottomTab
                    } else if viewStore.showAdjustmentView {
                        adjustmentBottomView
                    } else {
                        bottomTab
                    }
                    
                }
            }
            .onAppear {
                if viewStore.editThumbnail == nil {
                    viewStore.send(.fetchOriginalThumbnail(viewStore.media))
                }
            }
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    func bottomTabItemView(icon: String, label: String, enable: Bool = true) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                Image(systemName: icon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color.purple200)
                    .frame(width: 18, height: 18)
            }
            .frame(width: 36, height: 36)
            Text(label)
                .buttonRegular(Color.purple200)
            Spacer(minLength: 0)
        }
    }
}
