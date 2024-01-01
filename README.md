## README
과제를 진행하며 즐거운 시간을 보냈다는 말씀을 드리고 싶습니다. 주어진 과제들을 해결하면서 상당한 흥미를 느꼈고 센드버드에 대해 많이 배울 수 있는 기회이기도 했습니다.

### 폴더 구조
```
SendbirdUserManager
├── Package.swift
├── README.md
├── Sources
│   └── SendbirdUserManager
│       ├── Implementation
│       └── Requirements
└── Tests
    ├── SendbirdUserManagerTests
    │   ├── NetworkClientBaseTests.swift
    │   ├── SendbirdUserManagerTests.swift
    │   ├── UserManagerBaseTests.swift
    │   └── UserStorageBaseTests.swift
    └── SendbirdUserManagerSubtests
        ├── LRUCacheTests.swift
        └── RateLimiterTests.swift
```
#### Sources
- 제공해주신 프로토콜들은 모두 `Sources/SendbirdUserManager/Requirements` 폴더에 들어있습니다.
- 구현한 코드는 `Sources/SendbirdUserManager/Implementation`에 들어있습니다.
#### Tests
- 제공해주신 프로토콜에 대한 테스트는 `Tests/SendbirdUserManagerTests`에 들어있습니다.
- 추가로 구현한 코드에 대한 테스트는 `Tests/SendbirdUserManagerSubtests`에 들어있습니다.

### 개발환경
- Xcode 15
- Swift 5.8