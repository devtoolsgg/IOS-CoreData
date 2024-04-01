//
//  ListVC.swift
//  MyCoreData
//
//  Created by 이규관 on 2024/03/29.
//
 
import CoreData
import UIKit

class ListVC: UITableViewController {
    
    // datasource list
    lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
     
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // bar button
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add
                                     , target: self, action: #selector(add(_:)))
        self.navigationItem.rightBarButtonItem = addBtn
    }
    
}

// MARK: - tableview delegate
extension ListVC {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // datasource 가져오기
        let record = self.list[indexPath.row]
        let title = record.value(forKey: "title") as? String
        let contents = record.value(forKey: "contents") as? String
        
         
        // cell 지정
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = contents
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // 1. 선택된 행에 해당하는 데이터 가져오기
        let object = self.list[indexPath.row]
        let title = object.value(forKey: "title") as? String
        let contents = object.value(forKey: "contents") as? String
        
        let alert = UIAlertController(title: "게시글 수정", message: nil, preferredStyle: .alert)
        alert.addTextField() {$0.text = title}
        alert.addTextField() {$0.text = contents}
        
        // 버튼 추가
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            
            guard let title = alert.textFields?.first?.text,
                  let contents = alert.textFields?.last?.text else { return }
            
            // 값을 저장하고 성공이면 테이블뷰 리로드
            if self.edit(object: object, title: title, contents: contents) == true {
                
                // 지정된 셀의 내용을 수정
                let cell = self.tableView.cellForRow(at: indexPath)
                cell?.textLabel?.text = title
                cell?.detailTextLabel?.text = contents
                
                // 수정된 셀을 첫번째 행으로 이동함
                let firstIndex = IndexPath(item: 0, section: 0)
                self.tableView.moveRow(at: indexPath, to: firstIndex)
                
                self.tableView.reloadData()
            }
        })
        
        self.present(alert, animated: false)
        
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let object = self.list[indexPath.row] // 삭제되는 대상객체
        
        if self.delete(object: object) {
            // 코어데이터에서 삭제후 리시트와 테이블뷰의 리로드
            self.list.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - coredata CRUD
extension ListVC {
    
    // 데이터 저장 메소드
    func save(title: String, contents: String) -> Bool {
        
        // 1. 앱 델리게이트 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // 2. 관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
        
        // 3. 관리 객체 생성, 값 설정
        let object = NSEntityDescription.insertNewObject(forEntityName: "Board", into: context)
        object.setValue(title, forKey: "title")
        object.setValue(contents, forKey: "contents")
        object.setValue(Date(), forKey: "regdate")
        
        // 4. 저장소 커밋 후 list 갱신
        
        do {
            try context.save()
            
            //self.list.append(object) // append - 배열 가장 뒤에 추가
            self.list.insert(object, at: 0) // insert - 지정 인덱스에 추가
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    // 데이터 요청
    func fetch() -> [NSManagedObject] {
        
        // 1. 앱 델리게이트 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // 2. 관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
        
        // 3. 요청 객체 참조
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        
        // 3-1. 정렬 설정
        let sortByDate = NSSortDescriptor(key: "regdate", ascending: false)
        fetchRequest.sortDescriptors = [sortByDate]
        
        // 4. 데이터 가져오기
        let result = try! context.fetch(fetchRequest)
        return result
        
    }
    
    // 데이터 삭제
    func delete(object: NSManagedObject) -> Bool {
        
        // 1. 앱 델리게이트 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // 2. 관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
        
        // 3. 컨텍스트로부터 객체 삭제
        context.delete(object)
        
        // 4. 저장소에 커밋한다
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    func edit(object: NSManagedObject, title: String, contents: String) -> Bool {
        
        // 1. 앱 델리게이트 참조
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // 2. 관리 객체 컨텍스트 참조
        let context = appDelegate.persistentContainer.viewContext
         
        // 3. 관리 객체 생성, 값 설정
        object.setValue(title, forKey: "title")
        object.setValue(contents, forKey: "contents")
        object.setValue(Date(), forKey: "regdate")
        
        // 4. 저장소에 커밋한다
        do {
            try context.save()
            self.list = self.fetch()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}

// MARK: - action func
extension ListVC {
    
    @objc func add(_ sender: Any) {
        
        let alert = UIAlertController(title: "게시글 등록", message: nil, preferredStyle: .alert)
        alert.addTextField() {$0.placeholder = "제목"}
        alert.addTextField() {$0.placeholder = "내용"}
        
        // 버튼 추가
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            
            guard let title = alert.textFields?.first?.text,
                  let contents = alert.textFields?.last?.text else { return }
            
            // 값을 저장하고 성공이면 테이블뷰 리로드
            if self.save(title: title, contents: contents) == true {
                self.tableView.reloadData()
            }
        })
        
        self.present(alert, animated: false)
    
    }
    
}
