## README
과제를 진행하며 즐거운 시간을 보냈다는 말씀을 드리고 싶습니다. 주어진 과제들을 해결하면서 상당한 흥미를 느꼈고 센드버드에 대해 많이 배울 수 있는 기회이기도 했습니다. 기회 주셔서 감사합니다.
- [원래 사용하는 계정](https://github.com/enebin)에 public으로 올릴 경우 소스가 주변인에게 노출될 것 같아 부득이 새로운 계정을 만들어 게시하게 되었습니다. 양해 부탁드립니다.

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

### 참고사항 
- `os_log`를 래핑한 `Logger` 클래스를 추가했습니다.
    - 제공해주신 문서의 'SDK는 견고한 오류 처리를 포함해야하며, 차이점에 대한 자세한 피드백을 제공하고 가능한 수정을 제안해야 합니다'에 영향을 받았으며 또한 SDK를 개발하면서 얻은 경험으로 친절한 Logging과 에러 제공이 고객과의 커뮤니케이션 비용을 줄일 수 있음을 알게 되어 추가하게 되었습니다.
    - Log를 on/off 하거나 level을 조정하는 기능을 넣으려고 하였으나 주어진 인터페이스에서 마땅한 방법이 없어 제외하였습니다.
- In-memroy cache에 LRU 캐싱을 사용했습니다.
    - 혹시 모를 메모리 부족을 방지하기 위해 Max capacity를 제한하는 로직을 추가하였으나 별도의 지시사항이 없어 현재 구현에는 상한을 두지 않았습니다.