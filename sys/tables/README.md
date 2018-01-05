# Format v1.0.1
The **Format** library is a collection of functions used for formatting text
output. It contains functions that format a header string, and functions for
generating tables.

## Usage

Include the **Core** library, and the **Format** library.

```shell
source /proc/self/fd/0 <<<"$(< <(curl -ks https://codesilo.dimenoc.com/grahaml/triton/raw/master/core/include_core_lib))"
include format.shl
```

Then all of the functions in `format.shl` are available to use.

### Example

#### Code

```shell
init_table "Food"
add_row "Meat" "Fruit" "Vegetable"
add_row "Warthog" "Pineapple" "Eggplant"
add_row "Cow" "Watermelon" "Spinach"
add_row "Chicken" "Apple" "Carrot"
print_table
```

#### Output

```
============== Food ==============
 Meat    | Fruit      | Vegetable
---------|------------|-----------
 Warthog | Pineapple  | Eggplant
 Cow     | Watermelon | Spinach
 Chicken | Apple      | Carrot
```

## Functions

The following functions are available:

* `init_table()`
* `add_row()`
* `print_table()`
* `mkheader()`
* `mkpad()`

---

### init_table()
#### v1.1.0

#### Contributors
* Graham L. - Level 2 Support Technician - graham.l@hostdime.com

#### Description
Sets table title, color, partition, and text color. Resets these
values to default if none are specified by the user. Title is optional.

#### Options
`-c`, `--color` `COLOR`  
  Controls the color of the table glyphs are partitions. Set to 
  `$_DEFAULT_COLOR` if the option is not used. The value 'none' can be given
  instead of a *color* which forces no color to be used. This is useful if the
  table printed is going to be written to a log, or in another situation 
  where color codes are output.

`-C`, `--col`, `--column` `INTEGER`  
  Specifies the column for the `-P`, and `--col-partition` options. Default value 
  is 1. Does nothing when not used in conjunction with either the `-P`, or
  `--col-partition` option.

`-g`, `--glyph` `CHARACTER`  
  Controls the glyph character used in the table. Currently, the glyph is 
  only used to pad the header around the title. Must be exactly 1 character.
  Set to `$_DEFAULT_GLYPH` if the option is not used.

`-h`, `--heading` `INTEGER`  
Sets the number of rows to be printed before printing the headings divider
(default 1). Setting this value to anyting greater than 1 will make it no
longer compatible with markdown. If this number is greater than or equal to 
the number of rows, no divider will be printed.

`-m`, `--min-width` `INTEGER`  
  Sets the minimum table width. If the table width is not equal to or greater
  than the argument of `-m`, `--min-width`, then it will evenly increase the width
  of each column until the table's width is at least that large.

`-p`, `--partition` `STRING`  
  Controls the partition character used in the table. The parition is the 
  string used to separate each column. Set to `$_DEFAULT_PARTITION` if the 
  option is not used.

`-P`, `--col-partition` `STRING`  
  Specifies a partition used to separate columns that is different the one 
  used elsewhere in the table. This should be preceded by the `-C`, `--col`, or
  `--column` option to set which partition is affected. The partition affected
  will be the partition to the right of the column number. For example, using
  this option and setting the column to '3' will change the partition between
  the 3rd and 4th columns. The column specified is the last column, or 
  greater than the number of columns printed, this option does nothing.

`-t`, `--text-color` `COLOR`  
  Sets the text color for the title, and field text. Set to 
  `$_DEFAULT_TEXTCOLOR` if the option is not used.

`-T`, `--col-text-color` `COLOR`  
  Specifies a column's text color.This should be preceded by the `-C`, `--col`, or
  `--column` options to set the column. The column affected is the column in the 
  specified by the `-C`, `--col`, or `--column` option. For example, using this 
  option and setting the column to '3' will change the text color of the 3rd 
  column. If the column specified is greater than the number of columns 
  printed, this option does nothing.

#### Arguments 
Accepts a *string* to set the table title. This argument is optional.

#### Dependencies
* `core.shl::printerr()`

---

### add_row()
#### v1.0.0

#### Contributors
* Graham L. - Level 2 Support Technician - graham.l@hostdime.com

#### Description
Adds a new row to the table using the command line arguments as 
field values. The first use of this function after init_table() has been ran 
defines the number of columns for the table.

#### Options
`-C`, `--col`, `--column` `INTEGER`  
Specifies the column for the `-t`, and `--text-color` options. Default value is 1. 
Does nothing when not used in conjunction with either the `-t`, or `--text-color` 
option.

`-t`, `--text-color` `COLOR`  
  Sets the text color the fields in the row. Set to `$_DEFAULT_TEXTCOLOR` if the 
  option is not used. The value set by the `-T`, and `--col-text-color` option 
  has higher precedence.

`-T`, `--col-text-color` `COLOR`  
  Specifies a field's text color.This should be preceded by the `-C`, `--col`, or
  `--column` option to set the column. The field affected is the field in the 
  same column specified by the `-C`, `--col`, or `--column` option. For example, 
  using this option and setting the column to '3' will change the text color 
  of the field in the 3rd column of this row only. If the column specified is
  greater than the number of columns printed, this option does nothing.

#### Arguments
The values of in each field of the row should be passed as command 
line arguments. This uses positional parameters to get the field values, so 
any value containing a space should be quoted. To specify a field as 
intentionally blank, use empty quotes ('' or ""). If the number of fields is 
less than the number of columns, the remaing columns will be blank in this 
row. If the number of fields is greater than the number of columns, the row is 
trunctated to include only the first N fields where N is number of columns.

#### Dependencies
* `core.shl::printerr()`

---

### print_table()
#### v1.0.1

#### Contributors
* Graham L. - Level 2 Support Technician - graham.l@hostdime.com

#### Description
Prints the table as defined by `init_table()`, and `add_row()`.

#### Dependencies
* `mkheader()`

---

### mkheader()
#### v1.0.0

#### Contributors
* Graham L. - Level 2 Support Technician - graham.l@hostdime.com

#### Description
Outputs a title padded by glyphs on either side so it is defined
length with the title centered.

#### Options
`-c`, `--color` `COLOR`  
  Sets the color of the glyph used to the pad the title. Set to 
  `$_DEFAULT_COLOR` if the option is not used.

`-g`, `--glyph` `CHARACTER`  
  Controls the glyph character used in the padding. Must be exactly 1 
  character. Set to `$_DEFAULT_GLYPH` if the option is not used.

`-t`, `--text-color` `COLOR`  
  Sets the color of the title text. Set to `$_DEFAULT_TEXTCOLOR` if the option
  is not used.

`-w`, `--width` `INTEGER`  
  Sets the length of the header. Set to `$_DEFAULT_WIDTH` if the option is not 
  used.

#### Arguments
An argument containing the title must be provided on the command
line.

#### Dependencies
* `core.shl::printerr()`
* `mkpad()`

---

### mkpad()
#### v1.0.0

#### Contributors
* Graham L. - Level 2 Support Technician - graham.l@hostdime.com

#### Description
Creates a string of repeated 'glyphs' of arbitrary length.

#### Options
`-g`, `--glyph` `CHARACTER`  
  Controls the glyph character used in the padding. Must be exactly 1 
  character. Set to `$_DEFAULT_GLYPH` if the option is not used.

`-w`, `--width` `INTEGER`  
  Sets the length of the padding. Set to `$_DEFAULT_WIDTH` if the option is not 
  used.

#### Dependencies
* `core.shl::printerr()`

## Contributors
##### Graham L. - Level 2 Support Technician - graham.l@hostdime.com
