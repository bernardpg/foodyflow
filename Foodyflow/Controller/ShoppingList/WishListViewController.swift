//
//  WishListViewController.swift
//  Foodyflow
//
//  Created by 曹珮綺 on 6/26/22.
//

import UIKit
import SnapKit
import Kingfisher
import FirebaseAuth

// Login 跟 會擋到 

class WishListViewController: UIViewController, ShopButtonPanelDelegate {
    
    private lazy var notiname = Notification.Name("dropDownShopReloadNoti")

    private let wishBtn = ShoppingListBtnPanelView()
    
    var tabIndex: Int?
    
    var cate: [String?] = []
    
    var foodManager = FoodManager.shared
    
    // 狀態有改 reload filter 之後的篩選
    
    var shoppingLists: [String?] = []
    
    var foodsInShoppingList: [String?] = []
    
    var shopList: ShoppingList?
    
    var shoppingListView = ShoppingListView()
    
    var foodsInfo: [FoodInfo] = []
    
    var meatsInfo: [FoodInfo] = []
    
    var beansInfo: [FoodInfo] = []
    
    var eggsInfo: [FoodInfo] = []
    
    var vegsInfo: [FoodInfo] = []
    
    var picklesInfo: [FoodInfo] = []
    
    var fruitsInfo: [FoodInfo] = []
    
    var fishesInfo: [FoodInfo] = []
    
    var seafoodsInfo: [FoodInfo] = []
    
    var beveragesInfo: [FoodInfo] = []
    
    var seasonsInfo: [FoodInfo] = []
    
    var othersInfo: [FoodInfo] = []
    
    var onPublished: ( () -> Void)?
    
    var shopDidSelectDifferentRef: Int? { didSet { reloadWishList() } }
    
    @IBOutlet weak var wishListCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wishListCollectionView.delegate = self
        wishListCollectionView.dataSource = self
        wishListCollectionView.addSubview(wishBtn)
        setUI()
        wishBtn.delegate = self

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        wishListCollectionView.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global().async {
            self.fetchAllCate { [weak self] cates in
                self?.cate = cates
                semaphore.signal()
            }
            semaphore.wait()
            // fetch refrige fetch 購買清單  // fetch 食物 -> 分類
            // w for fix error 應該先fetch 在回來抓
            self.fetchAllShoppingListInSingleRefrige { [weak self] shoppingLists in
            self?.shoppingLists = shoppingLists
            print(shoppingLists)
            if shoppingLists.isEmpty {
                self?.cate = []
                DispatchQueue.main.async {
                        self?.wishListCollectionView.backgroundView = self?.shoppingListView
                        self?.wishListCollectionView.reloadData()
                    }} else {
            shoppingListNowID = self?.shoppingLists[self?.shopDidSelectDifferentRef ?? 0]
                self?.fetchAllFoodInfoInSingleShopList { [weak self] foodssInfo in
                    if foodssInfo.isEmpty {
                        self?.wishListCollectionView.backgroundView = self?.shoppingListView
                    } else {
                    if foodssInfo[0] == "" {
                        self?.wishListCollectionView.backgroundView = self?.shoppingListView } else {
                        
                        self?.wishListCollectionView.backgroundView = nil
                        self?.fetAllFood(foodID: foodssInfo, completion: { allfoodInfo in
                        let wishshopFoodInfo = allfoodInfo.filter { foodinfo in
                                foodinfo.foodStatus == 1 }
                            if                            wishshopFoodInfo.isEmpty {
                                DispatchQueue.main.async {
                                    self?.cate = []
                                    // lottie 消失
                                    self?.wishListCollectionView.reloadData()
                                    self?.wishListCollectionView.backgroundView = self?.shoppingListView }
                            }

                        guard let cates = self?.cate else { return }
                        self?.resetRefrigeFood()
                        self?.cateFilter(allFood: wishshopFoodInfo, cates: cates)
                        DispatchQueue.main.async {
                            // lottie 消失
                            self?.wishListCollectionView.reloadData()
                            semaphore.signal()
                        }
                    })
                    }

                }
            }
            }
    
            }
            semaphore.wait()

        }
    }
    
    private func reloadWishList() {
                
        self.fetchAllCate { [weak self] cates in self?.cate = cates }
            
        self.resetRefrigeFood()
        self.fetchAllShoppingListInSingleRefrige { [weak self] shoppingList in
            self?.shoppingLists = shoppingList
           //  crash point
            shoppingListNowID = self?.shoppingLists[self?.shopDidSelectDifferentRef ?? 0]
            print("\(shoppingListNowID)")
                self?.fetchAllFoodInfoInSingleShopList { [weak self] foodssInfo in
                    if foodssInfo.isEmpty {
                        self?.wishListCollectionView.backgroundView = self?.shoppingListView } else {
                    if foodssInfo[0] == "" {
                        DispatchQueue.main.async {
                            self?.cate = []
                            // lottie 消失
                            self?.wishListCollectionView.reloadData()
                            self?.wishListCollectionView.backgroundView = self?.shoppingListView } } else {
                        self?.wishListCollectionView.backgroundView = nil
                        self?.fetAllFood(foodID: foodssInfo, completion: { allfoodInfo in
                        let wishshopFoodInfo = allfoodInfo.filter { foodinfo in
                                    foodinfo.foodStatus == 1 }
                            if                            wishshopFoodInfo.isEmpty {
                                DispatchQueue.main.async {
                                    self?.cate = []
                                    // lottie 消失
                                    self?.wishListCollectionView.reloadData()
                                    self?.wishListCollectionView.backgroundView = self?.shoppingListView }
                            }

                            guard let cates = self?.cate else { return }
                            self?.resetRefrigeFood()
                            self?.cateFilter(allFood: wishshopFoodInfo, cates: cates)
                            DispatchQueue.main.async {
                                // lottie 消失
                                self?.wishListCollectionView.reloadData()
                            }
                        })}
                    }
                }

        }
    }
    
    private func alertSheet(food: FoodInfo) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "移至購買清單", style: .default, handler: { _ in
            self.foodManager.changeFoodStatus(foodId: foodId, foodStatus: 2) {
                self.reloadWishList()
        
        }
            
        }))
        alert.addAction(UIAlertAction(title: "編輯\(food.foodName!)", style: .default, handler: { _ in
            
            let shoppingVC = ShoppingListProductDetailViewController(
                nibName: "ShoppingListProductDetailViewController",
                bundle: nil)
            
            shoppingVC.shoppingList.foodID = self.foodsInShoppingList
            
            // MARK: - 邏輯在修改
            shoppingVC.foodInfo = food
    //        shoppingVC.refrige = refrige[0]
            self.navigationController!.pushViewController(shoppingVC, animated: true)

                print("User click Edit button")}))

        alert.addAction(UIAlertAction(title: "刪除\(food.foodName!)", style: .destructive, handler: { _ in
            
            self.foodManager.deleteFood(foodId: food.foodId) { error in
                    print("\(error)")}
            self.deleteFoodOnShoppingList(foodId: food.foodId ?? "") {
                print("success")}
            print("User click Delete button")}))
            
        alert.addAction(UIAlertAction(title: "返回", style: .cancel, handler: { _ in
                print("User click Dismiss button")}))
        self.present(alert, animated: true, completion: {
            print("completion block") })
        
    }

    func setUI() {

        wishBtn.translatesAutoresizingMaskIntoConstraints = false
        wishBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        wishBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        wishBtn.layer.backgroundColor = UIColor.FoodyFlow.btnOrange.cgColor
    }
        
    func resetRefrigeFood() {
        meatsInfo = []
        beansInfo = []
        eggsInfo = []
        vegsInfo = []
        picklesInfo = []
        fruitsInfo = []
        fishesInfo = []
        seafoodsInfo = []
        beveragesInfo = []
        seasonsInfo = []
        othersInfo = []
    }
    
    func cateFilter(allFood: [FoodInfo], cates: [String?]) {
        
        for foodInfo in allFood {
                for cate in cates {
                    guard let foodCategory = foodInfo.foodCategory else { return }
                    if foodCategory == cate! && cate! == "肉類"{ self.meatsInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "豆類"{
                        self.beansInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "雞蛋類"{
                        self.eggsInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "青菜類"{
                        self.vegsInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "醃製類"{
                        self.picklesInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "水果類"{
                        self.fruitsInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "魚類"{
                        self.fishesInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "海鮮類"{
                        self.seafoodsInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "飲料類"{
                        self.beveragesInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "調味料類"{
                        self.seasonsInfo.append(foodInfo) } else if
                        foodCategory == cate! && cate! == "其他"{
                        self.othersInfo.append(foodInfo) }}
            }

    }

    func fetchAllCate(completion: @escaping([String?]) -> Void) {
        CategoryManager.shared.fetchArticles(completion: { result in
            switch result {
            case .success(let cate):
                completion( cate[0].type )
            case .failure:
                print("cannot fetch cate data")
            }
        })
    }
    // fetch shoppingList number
    func fetchAllShoppingListInSingleRefrige(completion: @escaping([String?]) -> Void) {
        ShoppingListManager.shared.fetchAllShoppingListIDInSingleRefrige { result in
            switch result {
            case .success(let shoppingLists):
                completion(shoppingLists)
            case .failure:
            print("fetch shoppingList error")
                
            }
        }
    }
    // fetch single shoppingList FoodInfo
    func fetchAllFoodInfoInSingleShopList(completion: @escaping([String?]) -> Void) {
        ShoppingListManager.shared.fetchfoodInfoInsideSingleShoppingList { result in
            switch result {
            case .success(let foodsInfo):
                self.foodsInShoppingList = foodsInfo
                completion(foodsInfo)
                
            case .failure:
            print("fetch shoppingList error")
                
            }
        }
    }
    
    func didTapButtonWithText(_ text: Int) { verifyUser(btn: text) }
    
    private func verifyUser(btn: Int) {
        Auth.auth().addStateDidChangeListener { (_, user) in
            if user != nil {
                
                // create food
                if btn == 1 {
                    
                     // no refrige
                    if refrigeNow?.id == nil {
                        
                        self.whenFrigeIsEmptyAlert()
                        
                    }
                     // no shopList
                    else if self.shoppingLists.isEmpty {
                        self.whenShopListIsEmptyAlert()
                    } else {
                        
                    // create Food
                    let shoppingVC = ShoppingListProductDetailViewController(
                                nibName: "ShoppingListProductDetailViewController",
                                bundle: nil)
                            
                    shoppingVC.shoppingList.foodID = self.foodsInShoppingList
                    ShoppingListManager.shared.fetchShopListInfo(shopplingListID: shoppingListNowID) { [weak self ] result in
                    switch result {
                    case .success(let shopLists):
                    shoppingVC.shoppingList = shopLists ?? ShoppingList(id: "dd", title: "", foodID: [])
                    self?.navigationController!.pushViewController(shoppingVC, animated: true)

                    case .failure:
                        HandleResult.reportFailed.messageHUD
                        
                    }
                        
                    }
                    } } else if btn == 2 {
                    // create shopList
                    if refrigeNow?.id == nil {
                        
                        self.whenFrigeIsEmptyAlert()
                        } else {
                        self.createShoppingList()
                        }}
            } else {
                self.present(LoginViewController(), animated: true)
            }
        }

    }
    
    private func whenFrigeIsEmptyAlert() {
        
        let controller = UIAlertController(title: "尚未有食光冰箱", message: "請先在冰箱頁創立", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
            
        }
        controller.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            
        }
        controller.addAction(okAction)

        present(controller, animated: true, completion: nil)
        
    }
    
    private func whenShopListIsEmptyAlert() {
        
        let controller = UIAlertController(title: "尚未有購物清單", message: "請先創立購物清單", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
            
        }
        controller.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            
        }
        controller.addAction(okAction)

        present(controller, animated: true, completion: nil)
        
    }

    private func createShoppingList() {
        
        let alert = UIAlertController(title: "創建購物清單", message: nil, preferredStyle: .alert)
        
        let createAction = UIAlertAction(title: "建立清單", style: .default) { _ in
            
            guard let refrigeID = refrigeNow?.id else { return }
            
            var createNewShop = ShoppingList.init(id: "", title: "我的購物清單", foodID: [])
            
            self.promptForAnswer { createNewShopListName in
                createNewShop.title = createNewShopListName
                
                ShoppingListManager.shared.createShoppingList(shoppingList: &createNewShop, refrigeID: refrigeID) { result in
                    switch result {
                    case .success:
                        NotificationCenter.default.post(name: self.notiname, object: nil)
                        
                        DispatchQueue.main.async {
                            self.reloadWishList()
                        }
                        
                        HandleResult.addDataSuccess.messageHUD
                    case .failure:
                        HandleResult.addDataFailed.messageHUD
                    }
                }
        
            }
        }
        alert.addAction(createAction)
        
        let falseAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(falseAction)
        
        alert.show(animated: true, vibrate: false, completion: nil)
                
    }
    
    private func promptForAnswer(completion: @escaping (String) -> Void) {
        let alertVC = UIAlertController(title: "請填寫你購物清單的名字", message: "填寫你想紀錄的清單", preferredStyle: .alert)
        alertVC.addTextField()
        
        let submitAction = UIAlertAction(title: "確認", style: .default) { [unowned alertVC] _ in
            let answer = alertVC.textFields![0]
            
            guard let rename = answer.text else { return }
            completion(rename)
            // do something interesting with "answer" here
        }
        
        alertVC.addAction(submitAction)
        
        let falseAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertVC.addAction(falseAction)
        present(alertVC, animated: true)
    }

//    shoppingListNowID
    func fetAllFood(foodID: [String?], completion: @escaping([FoodInfo]) -> Void) {
        self.foodsInfo = []
        foodManager.fetchSpecifyFoodInShopping(foods: foodID, completion: { result in
            switch result {
            case .success(let foodsinfo):
                self.foodsInfo.append(foodsinfo)
                if self.foodsInfo.count == self.foodsInShoppingList.count { completion(self.foodsInfo) } else {
                    print("append not finish yet ") }

            case .failure:
                print("fetch shopplinglist food error")
            }
        })
    }
    
    // MARK: - finishShop to Refrige
    func finishShoppingToRefrige(foodId: String, complection: @escaping() -> Void) {
                
        refrigeNow!.foodID.append(foodId) // global
        RefrigeManager.shared.publishFoodOnRefrige(refrige: refrigeNow!) { result in
            switch result {
            case .success:
                // change food status
                self.foodManager.changeFoodStatus(foodId: foodId, foodStatus: 3) {
                    self.deleteFoodOnShoppingList(foodId: foodId) {
                        print("delete okay")
                    }
                    // 抓 fetch shoppingList foodInfo
                    // remove foodID
                                // d
                    
                }
            case .failure:
                print("cannot fetch cate data")
                        }
                    }
                }
    
    // MARK: - deleteFood
    func deleteFoodOnShoppingList(foodId: String, complection: @escaping() -> Void) {
        
        self.fetchAllFoodInfoInSingleShopList { foodsInfos in
            
            var newshoppingList: ShoppingList = ShoppingList(
                id: "", title: "", foodID: [""])
            
            newshoppingList.foodID = foodsInfos.filter { $0 != foodId }
            self.shoppingLists = newshoppingList.foodID

            ShoppingListManager.shared.postFoodOnShoppingList(shoppingList: &newshoppingList) { result in
                switch result {
                case .success:
                    self.fetchAllFoodInfoInSingleShopList { [weak self] foodssInfo in
                        if foodssInfo.isEmpty {
                            self?.cate = []
                            self?.wishListCollectionView.reloadData()
                            self?.wishListCollectionView.backgroundView = self?.shoppingListView } else {
                        if foodssInfo[0] == "" {
                            DispatchQueue.main.async {
                                self?.cate = []
                                // lottie 消失
                                self?.wishListCollectionView.reloadData()
                                self?.wishListCollectionView.backgroundView = self?.shoppingListView } } else {
                            self?.wishListCollectionView.backgroundView = nil
                            self?.fetAllFood(foodID: foodssInfo, completion: { allfoodInfo in
                                let wishshopFoodInfo = allfoodInfo.filter { foodinfo in
                                        foodinfo.foodStatus == 1 }
                                if                            wishshopFoodInfo.isEmpty {
                                    DispatchQueue.main.async {
                                        self?.cate = []
                                        // lottie 消失
                                        self?.wishListCollectionView.reloadData()
                                        self?.wishListCollectionView.backgroundView = self?.shoppingListView }
                                }
                                
                                guard let cates = self?.cate else { return }
                                self?.resetRefrigeFood()
                                self?.cateFilter(allFood: wishshopFoodInfo, cates: cates)
                                DispatchQueue.main.async {
                                    // lottie 消失
                                    self?.wishListCollectionView.reloadData()
                                }
                            })}
                        }
                    }

                 /*   self.fetAllFood(foodID: self.shoppingLists) { allfoodInfo in
                        if allfoodInfo.isEmpty {
                            self.cate = []
                            self.wishListCollectionView.backgroundView = SearchPlaceholderView()
                            self.wishListCollectionView.reloadData()
                        }
                        else{
                            
                        self.resetRefrigeFood()
                        if let cates = self.cate as? [String] {
                        self.cateFilter(allFood: allfoodInfo, cates: cates)
                        DispatchQueue.main.async {
                            // lottie 消失
                            self.wishListCollectionView.reloadData()
  //                          semaphore.signal()
                        }
                            
                        }
                        }}*/
                case .failure(let error):
                    print("publishArticle.failure: \(error)")
                }
            }
            
        }
        }
    
    // MARK: - create ShopList
    
    func createShopList(newshopList: ShoppingList, refrige: Refrige, completion: @escaping() -> Void) {
        
        var newshopList = newshopList
        ShoppingListManager.shared.createShoppingList(shoppingList: &newshopList, refrigeID: refrige.id) { result in
            switch result {
            case .success:
                HandleResult.addDataSuccess.messageHUD
            case .failure:
                HandleResult.addDataFailed.messageHUD
            }
        }
    }
    
    }

extension WishListViewController: UICollectionViewDataSource,
                                      UICollectionViewDelegate,
                                      UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return cate.count}
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return meatsInfo.count
        case 1:
            return beansInfo.count
        case 2:
            return eggsInfo.count
        case 3:
            return vegsInfo.count
        case 4:
            return picklesInfo.count
        case 5:
            return fruitsInfo.count
        case 6:
            return fishesInfo.count
        case 7:
            return seafoodsInfo.count
        case 8:
            return beveragesInfo.count
        case 9:
           return seasonsInfo.count
        case 10:
          return othersInfo.count
        default:
          return foodsInfo.count
        }
        
    }
        
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "shoppingListCollectionViewCell",
                for: indexPath) as? ShoppingListCollectionViewCell
        guard let cell = cell else { return UICollectionViewCell() }
        cell.layer.backgroundColor = UIColor(red: 1, green: 0.964, blue: 0.929, alpha: 1).cgColor
        cell.layer.cornerRadius = 20
        cell.shoppingItemImage.lkCornerRadius = 20
        switch indexPath.section {
        case 0:
            cell.shoppingName.text = meatsInfo[indexPath.item].foodName
            cell.shoppingItemImage.kf.setImage(with: URL( string: meatsInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = meatsInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = meatsInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 1:
            cell.shoppingName.text = beansInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: beansInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = beansInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = beansInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 2:
            cell.shoppingName.text = eggsInfo[indexPath.item].foodName
            
                cell.shoppingItemImage.kf.setImage(with: URL( string: eggsInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = eggsInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = eggsInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 3:
            cell.shoppingName.text = vegsInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: vegsInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = vegsInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = vegsInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 4:
            cell.shoppingName.text = picklesInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: picklesInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = picklesInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = picklesInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 5:
            cell.shoppingName.text = fruitsInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: fruitsInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = fruitsInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = fruitsInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 6:
            cell.shoppingName.text = fishesInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: fishesInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = fishesInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = fishesInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 7:
            cell.shoppingName.text = seafoodsInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: seafoodsInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = seafoodsInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = seafoodsInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 8:
            cell.shoppingName.text = beveragesInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: beveragesInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = beveragesInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = beveragesInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 9:
            cell.shoppingName.text = seasonsInfo[indexPath.item].foodName

                cell.shoppingItemImage.kf.setImage(with: URL( string: seasonsInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = seasonsInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = seasonsInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        case 10:
            cell.shoppingName.text = othersInfo[indexPath.item].foodName
                cell.shoppingItemImage.kf.setImage(with: URL( string: othersInfo[indexPath.item].foodImages ?? "" ))
            cell.shoppingBrand.text = othersInfo[indexPath.item].foodBrand
            cell.shoppingLocation.text = othersInfo[indexPath.item].foodPurchasePlace
            cell.shoppingWeight.isHidden = true
        default:
            cell.shoppingName.text = foodsInfo[indexPath.item].foodName
            
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "ShoppingListCollectionReusableView",
            for: indexPath) as? ShoppingListCollectionReusableView {
            sectionHeader.sectionHeaderlabel.text = self.cate[indexPath.section]
            sectionHeader.sectionHeaderlabel.font = UIFont(name: "PingFang TC", size: 20)
            return sectionHeader
        }
        return UICollectionReusableView()
    }

    private func collectionView(_ collectionView: UICollectionView,
                                layout collectionViewLayout: UICollectionViewLayout,
                                sizeForItemAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20.0, left: 16.0, bottom: 10.0, right: 16.0)
        }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: 200, height: 200) }

    // MARK: - single tap edit
    // MARK: - delete food or send to shoppingList to long gestture
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            alertSheet(food: meatsInfo[indexPath.item])
        case 1:
            alertSheet(food: beansInfo[indexPath.item])
        case 2:
            alertSheet(food: eggsInfo[indexPath.item])
        case 3:
            alertSheet(food: vegsInfo[indexPath.item])
        case 4:
            alertSheet(food: picklesInfo[indexPath.item])
        case 5:
            alertSheet(food: fruitsInfo[indexPath.item])
//            finishShoppingToRefrige(foodId: fruitsInfo[indexPath.item].foodId ?? "2") {
//                print("success to reFirge ")
//            }
//            deleteFoodOnShoppingList(foodId: fruitsInfo[indexPath.item].foodId ?? "2") {
//                print("success to delete " )
//            }
        case 6:
            alertSheet(food: fishesInfo[indexPath.item])
        case 7:
            alertSheet(food: seafoodsInfo[indexPath.item])
        case 8:
            alertSheet(food: beveragesInfo[indexPath.item])

        case 9:
            alertSheet(food: seasonsInfo[indexPath.item])

        case 10:
            alertSheet(food: othersInfo[indexPath.item])

        default:
            print("dd")
        }
    }
}
