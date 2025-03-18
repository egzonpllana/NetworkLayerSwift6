//
//  Interceptors.swift
//  NetworkingLayerSwift6
//
//  Created by Egzon Pllana on 15.3.25.
//

import EventHorizon

enum Interceptors {
    static let example: [any NetworkInterceptor] = [
        AuthInterceptor(tokenProvider: "my_token"),
        LoggingInterceptor(),
        RetryInterceptor(),
        RequestTimeoutInterceptor(timeout: 10),
        HeaderInjectorInterceptor(headers: ["User-Agent": "MyApp/1.0"])
    ]
}
