/**
    Multi-dimensional slices.

    Copyright © 2020-2025, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.slice;
import numem;

/**
    A contiguous 2-dimensional slice.

    The data is stored row-major.
*/
struct slice2d(T) {
private:
@nogc:
    T[] data_;
    size_t rows_;
    size_t columns_;

public:

    /**
        Pointer to the start of the data.
    */
    @property T* ptr() => data_.ptr;

    /**
        The total length of the slice's contiguous allocation.
    */
    @property size_t length() => data_.length;

    /**
        The rows of the slice.
    */
    @property size_t rows() => rows_;

    /**
        The columns of the slice.
    */
    @property size_t columns() => columns_;

    /**
        Constructs a new empty slice.

        Params:
            rows =      The number of rows in the slice.
            columns =   The number of columns in the slice.
    */
    this(uint rows, uint columns) {
        this.resize(rows, columns);
    }

    /**
        Resizes the 2D slice

        Params:
            rows =  The new row size of the slice
            cols =  The new column size of the slice.
    */
    void resize(uint rows, uint cols) {

        // NOTE:    When resizing from empty to non-empty, we can skip the
        //          other steps.
        if ((rows_ == 0 || columns_ == 0) && (rows > 0 && cols > 0)) {
            this.rows_ = rows;
            this.columns_ = cols;
            this.data_ = nu_malloca!T(rows_*columns_);
            return;
        }

        // Get which row/column pair is the smallest, then use that
        // for copying data over to the new array.
        size_t mRows = nu_min(cast(size_t)rows_, cast(size_t)rows);
        size_t mCols = nu_min(cast(size_t)columns_, cast(size_t)cols);

        auto oldData = data_;
        auto newData = nu_malloca!T(rows*cols);
        foreach(x; 0..mRows) {
            foreach(y; 0..mCols) {
                newData[(rows*y)+x] = oldData[(rows_*y)+x];
            }
        }

        this.rows_ = rows;
        this.columns_ = cols;
        this.data_ = newData;
        nu_freea(oldData);
    }

    /**
        Indexes the slice.

        Params:
            row =   The row to index
            col =   The column to index
        
        Returns:
            The item at the given row and column index
    */
    ref T opIndex(size_t row, size_t col) {
        assert(row <= rows_, "Row index outside bounds of array.");
        assert(col <= columns_, "Column index outside bounds of array.");

        return data_[(rows_*row)+col];
    }

    /**
        Frees the contents of the slice.
    */
    void free() {
        nu_freea(data_);
    }
}

@("slice2d")
unittest {
    slice2d!int ints;
    ints.resize(4, 4);
    ints[2, 2] = 24;

    ints.resize(8, 8);
    assert(ints[2, 2] == 24);
}