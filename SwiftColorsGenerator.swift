import Foundation
import Files

for catalog in try Folder.current.subfolders {
    print(catalog)
}
