//
// Copyright (C) 2017-2018 HERE Europe B.V.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

struct SettingsItem<Model> {

    var title: String
    var configuration: Model
}

class SettingsViewController<T>: UITableViewController {

    var data: [SettingsItem<T>] = []
    var didSelect: ((SettingsItem<T>) -> Void) = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"

        tableView.register(ComponentsCell.self, forCellReuseIdentifier: "ComponentsCell")
        tableView.backgroundColor = UIColor(named: "colorBackgroundLight")
        tableView.hideEmptyCells()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ComponentsCell") as? ComponentsCell else {
            fatalError("Failed to dequeue the cell")
        }

        cell.textLabel?.text = data[indexPath.row].title

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data[indexPath.row]
        didSelect(item)
        navigationController?.popViewController(animated: true)
    }
}