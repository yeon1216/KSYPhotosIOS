//
//  FontUtil.swift
//  KSYPhotos
//
//  Created by ksy on 7/9/24.
//

import SwiftUI


extension View {
    
    private func applyFont(_ font: Font, _ color: Color?) -> some View {
        self
            .font(font)
            .foregroundColor(color)
    }
    
    func header5Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.header5Bold, color)
    }
    func header6Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.header6Bold, color)
    }
    
    func subTitle1Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle1Bold, color)
    }
    func subTitle2Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle2Bold, color)
    }
    func subTitle3Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle3Bold, color)
    }
    func subTitle4Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle4Bold, color)
    }
    func subTitle5Bold(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle5Bold, color)
    }
    func subTitle1Medium(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle1Bold, color)
    }
    func subTitle2Medium(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle2Medium, color)
    }
    func subTitle3Medium(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle3Medium, color)
    }
    
    func subTitle2Regular(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle2Regular, color)
    }
    func subTitle3Regular(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle3Regular, color)
    }
    
    func bodyMedium(_ color: Color? = nil) -> some View {
        applyFont(Font.bodyMedium, color)
    }
    func bodyRegular(_ color: Color? = nil) -> some View {
        applyFont(Font.bodyRegular, color)
    }
    func body2Regular(_ color: Color? = nil) -> some View {
        applyFont(Font.body2Regular, color)
    }
    
    func buttonBold(_ color: Color? = nil) -> some View {
        applyFont(Font.buttonBold, color)
    }
    func buttonSemiBold(_ color: Color? = nil) -> some View {
        applyFont(Font.buttonSemiBold, color)
    }
    func buttonRegular(_ color: Color? = nil) -> some View {
        applyFont(Font.buttonRegular, color)
    }
    
    func captionBold(_ color: Color? = nil) -> some View {
        applyFont(Font.captionBold, color)
    }
    func captionRegular(_ color: Color? = nil) -> some View {
        applyFont(Font.captionRegular, color)
    }
    func captionMedium(_ color: Color? = nil) -> some View {
        applyFont(Font.captionMedium, color)
    }
    
    func chipMedium(_ color: Color? = nil) -> some View {
        applyFont(Font.chipMedium, color)
    }
    func chipSemiBold(_ color: Color? = nil) -> some View {
        applyFont(Font.chipSemiBold, color)
    }
    func chipBold(_ color: Color? = nil) -> some View {
        applyFont(Font.chipBold, color)
    }
    
    func subTitle1SemiBold(_ color: Color? = nil) -> some View {
        applyFont(Font.subTitle1SemiBold, color)
    }
    func overLineMedium(_ color: Color? = nil) -> some View {
        applyFont(Font.overLineMedium, color)
    }
}



extension Font {
    static let header5Bold = pretendard(size: 24, weight: .bold)
    static let header6Bold = pretendard(size: 20, weight: .bold)
    
    static let subTitle1Bold = pretendard(size: 18, weight: .bold)
    static let subTitle2Bold = pretendard(size: 16, weight: .bold)
    static let subTitle3Bold = pretendard(size: 14, weight: .bold)
    static let subTitle4Bold = pretendard(size: 13, weight: .bold)
    static let subTitle5Bold = pretendard(size: 11, weight: .bold)
    
    static let subTitle1Medium = pretendard(size: 18, weight: .medium)
    static let subTitle2Medium = pretendard(size: 16, weight: .medium)
    static let subTitle3Medium = pretendard(size: 14, weight: .medium)
    
    static let subTitle2Regular = pretendard(size: 16, weight: .regular)
    static let subTitle3Regular = pretendard(size: 14, weight: .regular)
    
    
    static let bodyMedium = pretendard(size: 16, weight: .medium)
    static let bodyRegular = pretendard(size: 16, weight: .regular)
    static let body2Regular = pretendard(size: 14, weight: .regular)
    
    static let buttonBold = pretendard(size: 14, weight: .bold)
    static let buttonSemiBold = pretendard(size: 14, weight: .semibold)
    static let buttonRegular = pretendard(size: 14, weight: .regular)
    
    static let captionBold = pretendard(size: 12, weight: .bold)
    static let captionRegular = pretendard(size: 12, weight: .regular)
    static let captionMedium = pretendard(size: 12, weight: .medium)
    
    static let chipMedium = pretendard(size: 12, weight: .medium)
    static let chipSemiBold = pretendard(size: 12, weight: .semibold)
    static let chipBold = pretendard(size: 12, weight: .bold)
    
    static let subTitle1SemiBold = pretendard(size: 18, weight: .semibold)
    static let overLineMedium = pretendard(size: 10, weight: .medium)
}




private func pretendard(size fontSize: CGFloat, weight: UIFont.Weight) -> Font {
    let familyName = "Pretendard"
    
    var weightString: String
    switch weight {
    case .black:
        weightString = "Black"
    case .bold:
        weightString = "Blod"
    case .heavy:
        weightString = "ExtraBold"
    case .ultraLight:
        weightString = "ExtraLight"
    case .light:
        weightString = "Light"
    case .medium:
        weightString = "Medium"
    case .regular:
        weightString = "Regular"
    case .semibold:
        weightString = "SemiBold"
    case .thin:
        weightString = "Thin"
    default:
        weightString = "Regular"
    }
    
    var uiFont = UIFont(name: "\(familyName)-\(weightString)", size: fontSize)
    
    if uiFont == nil {
        print("uiFont == nil")
        uiFont = .systemFont(ofSize: fontSize, weight: weight)
    }
    
    return Font(uiFont!)
}
