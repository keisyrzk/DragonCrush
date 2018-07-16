//
//  Array2D.swift
//  DBCrush
//
//  Created by Esteban on 10.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

struct Array2D<T> {
  let columns: Int
  let rows: Int
  private var array: Array<T?>
  
  init(columns: Int, rows: Int) {
    self.columns = columns
    self.rows = rows
    array = Array<T?>(repeating: nil, count: rows*columns)
  }
  
  subscript(column: Int, row: Int) -> T? {
    get {
      return array[row*columns + column]
    }
    set {
      array[row*columns + column] = newValue
    }
  }
}
