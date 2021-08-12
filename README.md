## V-Cowin
Bunch of programs writtern in V Programming Language for Vaccine availability checking utilizing Co-WIN Public APIs

### Usage
Command Line
```v
v run ./find_session_plain 13-08-2021
// Only shows whether vaccines are available or not (both paid & free)
```
If you need more details on the availability run
```v
v run ./find_session 13-08-2021
//Press enter to increment dates
```

```diff
- Important<span> District Code is hardcoded to Thiruvananthapuram
```

### TODO
- [ ]  UI Formating
- [ ]  User Input for State & District
- [ ]  Filter Free & Paid

### !!Disclaimer
> All of the code hosted in this repo for learning purpose only. I will not be responsible for any error or inaccuracy in the data or any damage caused by this. - Indrajith K L