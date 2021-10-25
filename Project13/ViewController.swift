//
//  ViewController.swift
//  Project13
//  Day 52-53-54
//  Created by Igor Polousov on 14.10.2021.
//

import CoreImage
import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet var filterLabel: UILabel!
    // Изображение на экране
    @IBOutlet var imageView: UIImageView!
    // аутлет для слайдера
    @IBOutlet var intensity: UISlider!
    // Переменная для текущего изображения
    var currentImage: UIImage!
    
    // Инструмент CoreImage для оценки результатов обработки изображений и выполнения анализа изображений
    var context: CIContext!
    //  Инструмент для обработки изображений
    var currentFilter: CIFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Название приложения в заголовке
        title = "Instafilter"
        // Добавлена кнопка в navigation controller с функцией importPicture
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        // Создан объект для анализа изображений
        context = CIContext()
        // Задан фильтр при загрузке приложения CISepiaTone
        currentFilter = CIFilter(name: "CISepiaTone")
        
    }
    // Функция importPicture для вызова imagePickerController
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Получили картинку
        guard let image = info[.editedImage] as? UIImage else { return }
        // Убрали imagePickerController
        dismiss(animated: true)
        // Текущее изображение равно полученному изображению
        currentImage = image
        
        // Начальное изображение для СIImage установлено currentImage
        let beginImage = CIImage(image: currentImage)
        // Установлено значение currentFilter, изображение CIImage as beginImage с ключом для ипользования введенного изображения
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    // Функция для кнопки changeFilter. Предоставляет список фильтров для выбора при помощи UIAlertController и функции setFilter()
    @IBAction func changeFilter(_ sender: UIButton) {
        let ac = UIAlertController(title: "Select filter", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Всплывающий контроллер для того чтобы в ipad список фильтров был возле кнопки changeFilter
        if let popoverController = ac.popoverPresentationController {
            // View которая содержит якорь для всплывающего меню
           popoverController.sourceView = sender
            // Прямоугольник которым определяется место якоря во view
            popoverController.sourceRect = sender.bounds
        }
        present(ac, animated: true)
    }
    
    // Функция setFilter задана как функция UIAlertAction
    func setFilter(action: UIAlertAction) {
        // Проверка что картинка выбрана и существует
        guard  currentImage != nil else {
            let ac = UIAlertController(title: "Choose photo first", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Okay", style: .default))
            present(ac, animated: true)
            return
        }
        // Проверка и задание названия действия в alert controller
        guard let actionTitle = action.title else { return }
        filterLabel.text = action.title
        // Задаётся название фильтра соотвественно выбранного названия действия
        currentFilter = CIFilter(name: actionTitle)
        // Задали для начального изображения СIImage изображение currentImage
        let beginImage = CIImage(image: currentImage)
        // Установлены значения для currentFilter
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    

    // Функция для кнопки save
    @IBAction func save(_ sender: Any) {
        // Проверка что картинка для сохранения задана
        guard let image = imageView.image else {
            let ac = UIAlertController(title: "Ooops", message: "There was no image chosen for save ", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default))
            present(ac, animated: true)
            return
        }
        // Метод для сохранения измененной картинки в фотоальбом с заданной функцией imageSave
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSave(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // Функция для кнопки слайдера при передвижении
    @IBAction func intensityChanged(_ sender: Any) {
        applyProcessing()
    }
    
    func applyProcessing() {
        // Параметр для всех возможных параметров currentFilter
        let inputKeys = currentFilter.inputKeys
        
        // Проверки на содержание ключа для выбранного фильтра
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey)
        }
        
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(intensity.value * 200, forKey: kCIInputRadiusKey)
        }
        
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey)
        }
        
        if inputKeys.contains(kCIInputCenterKey) {
            currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
        }
        
        // Проверка на наличие изображения в инструменте currentFilter
        guard let outputImage = currentFilter.outputImage else { return }
        // Создание (получение) изображения CIImage при помощи иструмента context
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            // Если изображение получено при помощи context, то создаем объект UIImage, конвертируем в UIImage
            let processedImage = UIImage(cgImage: cgImage)
            // Присваеваем значение
            imageView.image = processedImage
        }
    }
    
    @objc func imageSave(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // Если будет выброшена ошибка
        if let error = error {
            // То всплывает alert controller
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default))
        } else {
            // Если сохранение прошло успешно
            let ac = UIAlertController(title: "Saved!", message: "You altered image has been seved to your photos", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default))
            present(ac, animated: true)
        }
    }
    
}

