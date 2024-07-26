//
//  KSYSeekBar.swift
//  KSYPhotos
//
//  Created by ksy on 7/16/24.
//

import SwiftUI

struct KSYSeekBar: View {
    
    var bounds: ClosedRange<CGFloat>
    @Binding var value: CGFloat
    @State private var seekBarWidth: CGFloat = 0.0
    @State private var seekValue: CGFloat = 0.0
    var seekBarPointerType: SeekBarPointerType
    var setValue: (CGFloat, Bool) -> Void
    
    enum SeekBarPointerType {
        case none, leading, center, trailing
    }
    
    init(
        value: Binding<CGFloat>,
        seekBarPointerType: SeekBarPointerType = .center,
        bounds: ClosedRange<CGFloat> = 0.0...1.0,
        setValue: @escaping (CGFloat, Bool) -> Void
    ) {
        self._value = value
        self.seekBarPointerType = seekBarPointerType
        self.bounds = bounds
        self.setValue = setValue
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    seekBar
                }
                .onAppear {
                    seekBarWidth = geo.size.width
                    seekValue = seekBarWidth * ((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
                }
                .onChange(of: value) { v in
                    seekValue = seekBarWidth * ((v - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
                }
            }
        }
        .frame(height: 16)
    }
    
    var seekBarBackground: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(width: seekBarWidth, height: 4)
            .background(Color.gray500)
            .cornerRadius(3)
    }
    
    var seekBarHandler: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0).frame(width: seekValue)
                Image(systemName: "circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.nenioWhite)
                    .frame(width: 16, height: 16)
                    .offset(x: -8)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                let location = v.location.x
                                seekValue = max(0, min(seekValue + location, seekBarWidth))
                                value = bounds.lowerBound + (seekValue * (bounds.upperBound - bounds.lowerBound)) / seekBarWidth
                                setValue(value, true)
                            }
                            .onEnded { v in
                                setValue(value, false)
                            }
                    )
            }
            Spacer(minLength: 0)
        }
        .frame(width: seekBarWidth, height: 4)
    }
    
    var seekBar: some View {
        ZStack {
            seekBarBackground
            HStack(spacing: 0) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: seekValue, height: 6)
                    .background(Color.purple500)
                    .cornerRadius(3)
                Spacer(minLength: 0)
            }
            .frame(width: seekBarWidth, height: 4)
            seekBarHandler
        }
        .frame(height: 16)
    }
    
}

struct KMASeekBar_Previews: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            Color.nenioWhite.ignoresSafeArea()
            TestSeekBarView()
        }
    }
}

struct TestSeekBarView: View {
    
    @State private var sliderValue: CGFloat = 0.2

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                KSYSeekBar(
                    value: $sliderValue,
                    seekBarPointerType: .center,
                    setValue: { newValue, changed in
                        sliderValue = newValue
                    }
                )
                .padding(.horizontal, 24)
            }.frame(height: 80)
            
            Text("Slider Value: \(sliderValue)")
                .padding()
            Spacer()
        }
    }
}
