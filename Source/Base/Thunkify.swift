//
//  Thunkify.swift
//  Pods
//
//  Created by Zhixuan Lai on 5/27/16.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public func thunkify<A, T>(function: @escaping (A, (T) -> Void) -> Void) -> ((A) -> Task<T>) {
    return {a in Task<T> {callback in function(a, callback) } }
}

public func thunkify<A, B, T>(function: @escaping (A, B, (T) -> Void) -> Void) -> ((A, B) -> Task<T>) {
    return {a, b in Task<T> {callback in function(a, b, callback) } }
}

public func thunkify<A, B, C, T>(function: @escaping (A, B, C, (T) -> ()) -> ()) -> ((A, B, C) -> Task<T>) {
    return {a, b, c in Task<T> {callback in function(a, b, c, callback) } }
}

public func thunkify<A, B, C, D, T>(function: @escaping (A, B, C, D, (T) -> ()) -> ()) -> ((A, B, C, D) -> Task<T>) {
    return {a, b, c, d in Task<T> {callback in function(a, b, c, d, callback) } }
}
