//
//  ContentView.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dice")
                .font(.system(size: 52))
                .accessibilityHidden(true)

            Text("BoardMate")
                .font(.largeTitle.bold())

            Text("보드메이트")
                .font(.title3)

            Text("주사위 · 모래시계 · 토큰")
                .font(.headline)
                .padding(.top, 12)

            Text("하나의 책상에서 만나는 보드게임 도구함")
                .font(.body)
                .multilineTextAlignment(.center)

            Text("프로젝트 준비 완료 · 기능 구현 예정")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color(red: 0.22, green: 0.16, blue: 0.12))
        .background(Color(red: 0.96, green: 0.94, blue: 0.90))
    }
}
