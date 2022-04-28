//
//  ViewController.swift
//  testRxSwift
//
//  Created by yuki.osu on 2021/02/17.
//

import UIKit
import RxSwift
import RxCocoa

extension ObservableType {
    
    func catchErrorJustComplete() -> Observable<Element> {
            return catchError { _ in
                return Observable.empty()
            }
        }
    
    func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { error in
            return Driver.empty()
        }
    }
        
    func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
    
}

class ViewController: UIViewController {

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var text1: UITextField!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    
    let disposeBag = DisposeBag()
    var tapGesture: UITapGestureRecognizer!

    var count1: Int = 1
    var count2: Int = -1
    var count3: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let publisher1: PublishSubject<Void> = PublishSubject<Void>()
        let stream1: Observable<Int> = publisher1.asObserver()
            .flatMap { _ -> Single<Int> in
                self.count1 += 1
                return Single<Int>.just(self.count1)
            }
            .asObservable()
            .debug("[s1]", trimOutput: false)
            .share(replay: 1)

        let publisher2: PublishSubject<Void> = PublishSubject<Void>()
        let stream2: Observable<Int> = publisher2.asObserver()
            .flatMap { _ -> Single<Int> in
                self.count2 -= 1
                return Single<Int>.just(self.count2)
            }
            .asObservable()
            .debug("[s2]", trimOutput: false)
            .share(replay: 1)

        #if false
        let target = Observable.zip(
            stream1,
            stream2
        )
        .debug("[target]", trimOutput: false)
        #else
        let target = Observable.combineLatest(
            stream1,
            stream2.take(1)
        )
        .debug("[target]", trimOutput: false)
        #endif

        let combine = Observable.combineLatest(stream1, stream2)
        let target2 = button4.rx.tap
            .withLatestFrom(combine)
            .map { (s1, s2) -> String in
                self.count3 += 100
                return "\(s1), \(s2), \(self.count3)"
            }

        stream1.asDriver(onErrorDriveWith: .empty())
            .map { String($0) }
            .drive(label1.rx.text)
            .disposed(by: disposeBag)

        stream2.asDriver(onErrorDriveWith: .empty())
            .map { String($0) }
            .drive(label2.rx.text)
            .disposed(by: disposeBag)

        target.asDriver(onErrorDriveWith: .empty())
            .map { "\($0), \($1)" }
            .drive(label3.rx.text)
            .disposed(by: disposeBag)

        button1.rx.tap
            .subscribe(onNext: { _ in
                publisher1.onNext(())
            })
            .disposed(by: self.disposeBag)

        button2.rx.tap
            .subscribe(onNext: { _ in
                publisher2.onNext(())
            })
            .disposed(by: self.disposeBag)

        target2.asDriver(onErrorDriveWith: .empty())
            .drive(label4.rx.text)
            .disposed(by: self.disposeBag)
    }
}
