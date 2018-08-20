import Foundation
import Files

struct ColorSet: Codable {
    var colors: [ColorInfo]
    var info: FileInfo
    var name: String?
}

struct FileInfo: Codable {
    var version: Float
    var author: String
}

struct ColorInfo: Codable {
    var idiom: String
    var color: Color
}

struct Color: Codable {
    var components: ColorComponents
}

struct ColorComponents: Codable {
    var red: String
    var green: String
    var blue: String
    var alpha: String
}

let folder: Folder = Folder.current
var allAssets: [Folder] = [Folder]()
var colors: [ColorSet] = [ColorSet]()

func assets(from folder: Folder) {
    for directory in folder.subfolders {
        if directory.name.contains(".xcassets") {
            allAssets.append(directory)
        } else {
            assets(from: directory)
        }
    }
}

func colorAssets() -> [Folder] {
    var colors: [Folder] = [Folder]()
    for asset in allAssets {
        for subfolder in asset.subfolders where subfolder.name.contains(".colorset") {
            colors.append(subfolder)
        }
    }
    return colors
}

func contentFiles(from folders: [Folder]) {
    for folder in folders {
        let data = try? folder.file(named: "Contents.json").read()
        if let data = data {
            do {
                var color = try JSONDecoder().decode(ColorSet.self, from: data)
                color.name = folder.name.replacingOccurrences(of: ".colorset", with: "")
                colors.append(color)
            } catch {
                print(error)
            }
        }
    }
}

func generateFile() {
    let subfolderName = "MarathonGenerated"
    
    var subfolder = try? folder.subfolder(named: subfolderName)
    if subfolder == nil  { subfolder = try? folder.createSubfolder(named: subfolderName) }
    
    let fileName = "UIColor+Extensions.generated.swift"
    var file = try? subfolder!.file(named: fileName)
    if file == nil { file = try? subfolder!.createFile(named: fileName) }
    
    var fileContent = """
        // This is autogenarated file.
        // DO NOT EDIT!
        // Author: Jakub Mazur, Copyright: wingu GmbH
        // Generated with Marathon by @johnsundell
        //
        import Foundation
        import UIKit


        """
    fileContent.append("extension UIColor {\n")
    for color in colors {
        fileContent.append("    static let \(color.name ?? "")")
        fileContent.append(": UIColor = #colorLiteral(")
        if let components = color.colors.last?.color.components {
            fileContent.append("red: \(components.red), ")
            fileContent.append("green: \(components.green), ")
            fileContent.append("blue: \(components.blue), ")
            fileContent.append("alpha: \(components.alpha)")
            fileContent.append(")\n")
        }
    }
    fileContent.append("}\n")
    print(fileContent)
    do {
        try file!.write(data: fileContent.data(using: .utf8)!)
    } catch {
        print(error)
    }
}

assets(from: folder) /* scan whole project and find .xcassets */
contentFiles(from: colorAssets()) /* create color assets references */
generateFile()
