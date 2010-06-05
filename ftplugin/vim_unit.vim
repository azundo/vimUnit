" Normally za or zR will open the folds- zM will close them all.
" File header {{{1
" --------------------------------------------------------------
"  FILE:            vimUnit.vim
"  AUTHOR:          Staale Flock, Staale -- lexholm .. no
"  MODIFIED:        Ben Best
"  VERSION:         0.2
"  LASTMODIFIED:    31 May 2010
"
"  PURPOSE:
"       To provide vim scripts with a simple unit testing framework and tools.
"       The framework and tools should resemble JUnit's interface definitions
"       to ease usage of both frameworks (and others based on JUnit). 
"       Obviously vim scripts are not java so I will only try to implement the
"       stuff useful to vim scripts. As a first milestone I think the 
"       junit.Assert and junit.TestResult classes to get a vim-script
"       unit-testing environment going. Modified to use an object instead of
"       lengthy VUAssert calls.
"       
"  WHY:
"       Well, I have been working on some vim-scripts and read a lot of them
"       the last two weeks and I really, really miss my unit-test (and
"       mock-object, but that is fare fetched I think..:O) tools to get my own
"       stuff of the ground (and making modifications to your's).
"       
"  THOUGHTS:
"       Writing unit-test code against a UI environment is often very difficult 
"       or demanding to creative solutions to be productive. We would like to 
"       have a mock-object framework to go with the unit-testing framework.
"       
"  INSTALLATION:
"       Place this file in your plugin directory (~/.vim/ftplugin/)
"       When you start vim again and open a vim file for editing you should
"       get a message that vimUnit has installed its documentation.
"       To get you started you could try :h vimUnit
"       
"  TIPS:
"       Documentation (when written..:o) is found at the bottom of this file. 
"       Thanks to code from vimspell.vim it should be self-installing the first
"       time this module is loaded
"
"       If your new to test-first principles and thinking you should start
"       with the article: 
"           http://junit.sourceforge.net/doc/testinfected/testing.htm
"       And then surf the web on these locations:
"           http://www.junit.org/
"           http://xprogramming.com/
"           http://www.extremeprogramming.org/
" 
"  NOTE:
"       8 Nov 2004 (v 0.1) This is my initial upload. The module is fare 
"       from finished. But as I could do with some input from other vim users
"       So I have chosen to let people know I'm working on it. 
"
"       To be conform with vim-script naming conventions functions are
"       prepended with VU (VimUnit). So stuff you would normaly would call 
"       VUAssert are called VUAssert, TestRunner* are called VURunner and so on.
"       Global variables starts with vimUnit*
"       

"       
"  CREDITS:
"
"  Best Regards
"  Staale Flock, (staale -- lexholm .. no)
"  Norway
" ---------------------------------------------------------------------------
"  
" A first try on unit testing vim scripts
" TODO: How do I unit test autocmd's?
" TODO: How do I unit test map, imap and so on?
" TODO: How do I unit test buffers
" TODO: how do I unit test windows
" TODO: how do I unit test the CTRL-W (wincmd) commands?


" Define true and false {{{1
if !exists('g:false')
    let g:FALSE = (1 != 1)
endif
if !exists('g:true')
    let g:TRUE = (1 == 1)
endif
if !exists('false')
    let false = g:FALSE
endif
if !exists('true')
    let true = g:TRUE
endif
if !exists('*TRUE')
    function! TRUE()
        let sFoo = (1 == 1)
        return sFoo
    endfunction
endif
if !exists('*FALSE')
    function! FALSE()
        let sFoo = (1 != 1)
        return sFoo
    endfunction
endif 

"Variables {{{1
"   Variables Global{{{2
"   Global variables might be set in vimrc

if !exists('g:vimUnitSelfTest')
"   1 ==> Always run self test when loaded
"   0 ==> Do not run self test when loaded. SelfTest will however run if the
"   file is modified since the documentation was installed.
    let g:vimUnitSelfTest = 0
endif

if !exists('g:vimUnitVerbosity')
    "At the moment there is just 0 (quiet) and 1(verbose)
    let g:vimUnitVerbosity = 1
endif

"   Buffer Variables {{{2
if !exists('b:testSuites')
    let b:testSuites = {}
endif

" A FunctionRegister object to keep track of objects' anonymous functions {{{1
" This object is a singleton so we only have to add objects to it once
if !exists('FunctionRegister')
    let FunctionRegister = {}
    let FunctionRegister.functions = {}
endif

function! FunctionRegister.AddObject(obj, name) dict
    for key in keys(a:obj)
        if type(a:obj[key]) == type(function('tr'))
            let func_name = string(a:obj[key])
            let func_num = matchstr(func_name, '\d\+')
            let self.functions[func_num] = a:name .'.'. key
        endif
    endfor
endfunction

" -----------------------------------------
" FUNCTION: FunctionRegister.ParseThrowpoint {{{2
" PURPOSE:
"   Substitute any anonymous function numbers with references if in
"   FunctionRegister
" ARGUMENTS:
"   throwpoint: the v:throwpoint variable
" RETURNS:
"   parsed throwpoint with values from functionRegister.functions
" -----------------------------------------
function! FunctionRegister.ParseThrowpoint(throwpoint) dict
    " Throwpoints are formatted as function func1..func2..func3, line n
    " Want to grab the func1..func2..func3 as the function_stack
    let function_stack = matchlist(a:throwpoint, 'function \(.*\),')[1]
    " copy the function stack
    let better_stack = function_stack
    " split the function stack by the delimiting .. to get function names
    let function_names = split(function_stack, '\.\.')
    for function_name in function_names
        " look for function names in the register
        if has_key(self.functions, function_name)
            " substitude better names
            let better_name = self.functions[function_name]
            let better_stack = substitute(better_stack, function_name, better_name, "g")
        endif
    endfor
    " substitute better function stack into throwpoint
    return substitute(a:throwpoint, function_stack, better_stack, "")
endfunction



" UnitTest Object {{{1
"
"   Main UnitTest object definition{{{2
if !exists('UnitTest')
    let UnitTest = {}
endif

" -----------------------------------------
" FUNCTION: UnitTest.init {{{2
" PURPOSE:
"   Provides a class instantiator for the UnitTest class
" ARGUMENTS:
"   name:   The name given to the UnitTest instance for printouts
" RETURNS:
"   new UnitTest instance
" -----------------------------------------
function! UnitTest.init(name) dict
    let instance = copy(self)
    let instance.testRunCount = 0
    let instance.testRunSuccessCount = 0
    let instance.testRunFailureCount = 0
    let instance.testRunErrorCount = 0
    let instance.name = a:name
    let instance.functionRegister = g:FunctionRegister
    return instance
endfunction


" -----------------------------------------
" FUNCTION: UnitTest.BuildException {{{2
" PURPOSE:
"   Builds a vimUnitTestFailure exception.
" ARGUMENTS:
"   caller: the function raising the exception
"   msg: a message to be printed with the exception
" RETURNS:
"   Exception string
" -----------------------------------------
function! UnitTest.BuildException(caller, msg) dict
    return "vimUnitTestFailure: ".a:caller.": ".a:msg
endfunction

" -----------------------------------------
" FUNCTION: UnitTest.TODO: {{{2
" PURPOSE:
"   Just a reminder that a function is not (fully) implemented.
" ARGUMENTS:
"   funcName:   The name of the calling function
" RETURNS:
"   false
" -----------------------------------------
function! UnitTest.TODO(funcName) dict
    echomsg '[TODO] '.a:funcName
    return FALSE()
endfunction

" ---------------------------------------------------------------------
" FUNCTION: UnitTest.AssertEquals {{{2
" PURPOSE:
"   Compare arguments
" ARGUMENTS:
"   arg1 : Argument to be tested.
"   arg2 : Argument to test against.
"   ...  : Optional message.
" RETURNS:
"   0 if arg1 == arg2
"   1 if arg1 != arg2
" ---------------------------------------------------------------------
function! UnitTest.AssertEquals(arg1, arg2, ...) dict
    if type(a:arg1) == type(a:arg2) && a:arg1 == a:arg2
        let bFoo = TRUE()
    else
        let bFoo = FALSE()
        let msg = string(a:arg1).' != '.string(a:arg2).'.'
        " only include message if it exists
        if a:0 > 0
            let msg = msg.' '.a:1
        endif
        throw self.BuildException("AssertEquals", msg)
    endif
    return bFoo
endfunction
" ---------------------------------------------------------------------
" FUNCTION: UnitTest.AssertNotEquals "{{{2
" PURPOSE:
"   Compare arguments
" ARGUMENTS:
"   arg1 : Argument to be tested.
"   arg2 : Argument to test against.
"   ...  : Optional message.
" RETURNS:
"   1 if arg1 == arg2
"   0 if arg1 != arg2
" ---------------------------------------------------------------------
function! UnitTest.AssertNotEquals(arg1, arg2, ...) dict
    if (type(a:arg1) == type(a:arg2) && a:arg1 != a:arg2) || type(a:arg1) != type(a:arg2)
        let bFoo = TRUE()
    else
        let bFoo = FALSE()
        let msg = string(a:arg1).' == '.string(a:arg2).'.'
        " only include message if it exists
        if a:0 > 0
            let msg = msg.' '.a:1
        endif
        throw self.BuildException("AssertNotEquals", msg)
    endif
    return bFoo
endfunction

" ---------------------------------------------------------------------
" FUNCTION: UnitTest.AssertTrue {{{2
" PURPOSE:
"   Check that the passed argument validates to true
" ARGUMENTS:
"   arg1: Should validate to TRUE() == (1==1)
"   ... : Optional message placeholder.
" RETURNS:
"   TRUE() if true and
"   FALSE() if false
" ---------------------------------------------------------------------
function! UnitTest.AssertTrue(arg1, ...) dict
    let bFoo = FALSE()
    let arg_type = type(a:arg1)
    let arg_as_string = ""
    if arg_type == type(0)
        if a:arg1 == TRUE()
            let bFoo = TRUE()
        else
            let bFoo = FALSE()
        endif
    elseif arg_type == type([])
        if a:arg1 == []
            let bFoo = FALSE()
        else
            let bFoo = TRUE()
        endif
    elseif arg_type == type({})
        if a:arg1 == {}
            let bFoo = FALSE()
        else
            let bFoo = TRUE()
        endif
    elseif arg_type == type("")
        if a:arg1 == ""
            let bFoo = FALSE()
        else
            let bFoo = TRUE()
        endif
    elseif arg_type == type(0.0)
        if a:arg1 == 0.0
            let bFoo = FALSE()
        else
            let bFoo = TRUE()
        endif
    endif

    if bFoo == FALSE()
        let msg = string(a:arg1).' is not True.'
        " only include message if it exists
        if a:0 > 0
            let msg = msg.' '.a:1
        endif
        throw self.BuildException("AssertTrue", msg)
    endif

    return bFoo
endfunction
" ---------------------------------------------------------------------
" FUNCTION:  UnitTest.AssertFalse {{{2
" PURPOSE:
"   Test if the argument equals false
" ARGUMENTS:
"   arg1:   Contains something that will be evaluated to true or false
" RETURNS:
"   0 if true
"   1 if false
" ---------------------------------------------------------------------
function! UnitTest.AssertFalse(arg1, ...) dict
    let bFoo = FALSE()
    let arg_type = type(a:arg1)
    let arg_as_string = ""
    if arg_type == type(0)
        if a:arg1 == FALSE()
            let bFoo = TRUE()
        else
            let bFoo = FALSE()
        endif
    elseif arg_type == type([])
        if a:arg1 == []
            let bFoo = TRUE()
        else
            let bFoo = FALSE()
        endif
    elseif arg_type == type({})
        if a:arg1 == {}
            let bFoo = TRUE()
        else
            let bFoo = FALSE()
        endif
    elseif arg_type == type("")
        if a:arg1 == ""
            let bFoo = TRUE()
        else
            let bFoo = FALSE()
        endif
    elseif arg_type == type(0.0)
        if a:arg1 == 0.0
            let bFoo = TRUE()
        else
            let bFoo = FALSE()
        endif
    endif

    if bFoo == FALSE()
        let msg = string(a:arg1).' is not False.'
        " only include message if it exists
        if a:0 > 0
            let msg = msg.' '.a:1
        endif
        throw self.BuildException("AssertFalse", msg)
    endif

    return bFoo
endfunction

" ---------------------------------------------------------------------
" FUNCTION: UnitTest.AssertFail {{{2
" PURPOSE:
"   Explicitly cause a test failure
" ARGUMENTS:
"   ...  : Optional message.
" RETURNS:
"   raises UnitTestFailed exception
" ---------------------------------------------------------------------
function! UnitTest.AssertFail(...) dict "{{{2
    let msg = "Failure asserted."
    if a:0 > 0
        let msg = msg.' '.a:1
    endif
    throw self.BuildException("AssertFail", msg)
    return FALSE()
endfunction

" ---------------------------------------------------------------------
" FUNCTION: UnitTest.AssertRaises {{{2
" PURPOSE:
"   Test that a call to a function raises a particular exception
" ARGUMENTS:
"   exception : Pattern for the exception to be raised.
"   func_ref : Function reference to call.
"   func_args : a list with all function arguments.
"   ...  :  Optional dictionary to bind to call (if we're dealing with
"           an object
"           Optional message.
" RETURNS:
"   1 if exception is raised when func_ref is called with func_args
"   raises UnitTestFailed exception otherwise
" ---------------------------------------------------------------------
function! UnitTest.AssertRaises(exception, Func_ref, func_args, ...) dict
    let bFoo = 0
    let extra_msg = ""
    let bindDict = 0
    if a:0 > 0
        if type(a:1) == type({})
            " here we have a dictionary to bind to the call
            let bindDict = 1
            if a:0 > 1
                let extra_msg = a:2
            endif
        else
            let extra_msg = a:1
        endif
    endif
    try
        if bindDict == 1
            " Add the dictionary to be bound
            let s = call(a:Func_ref, a:func_args, a:1)
        else
            let s = call(a:Func_ref, a:func_args)
        endif
    catch 
        " set bFoo to 1 if we get the expected exception
        if match(v:exception, a:exception) != -1
            let bFoo = 1
        endif
    endtry
    if bFoo != 1
        let msg = string(a:Func_ref).' called with args '.string(a:func_args).' did not raise exception matching '.a:exception.'.'
        " add extra_msg here
        let msg = msg.' '.extra_msg
        throw self.BuildException("AssertRaises", msg)
    endif
    return bFoo
endfunction

" -----------------------------------------
" FUNCTION: UnitTest.RunTests {{{2
" PURPOSE:
"   Run tests contained in the current object
" ARGUMENTS:
"   None
" RETURNS:
"   None
" -----------------------------------------

function! UnitTest.RunInSuite(suite) dict
    for key in keys(self)
        if strpart(key, 0, 4) == 'Test' && type(self[key]) == type(function("tr"))
            try
                call self[key]()
                call a:suite.AddTestResult(key, '.')
            catch /vimUnitTestFailure/
                call a:suite.AddTestResult(key, 'F', v:exception, v:throwpoint)
            catch
                call a:suite.AddTestResult(key, 'E', v:exception, v:throwpoint)
            endtry
        endif
    endfor
endfunction


" TestSuite Object {{{1
if !exists('TestSuite')
    let TestSuite = {}
endif

function! TestSuite.init(name) dict
    let instance = copy(self)
    let instance.name = a:name
    let instance.tests = []
    let instance.status_string = ""
    let instance.run_count = 0
    let instance.success_count = 0
    let instance.failure_count = 0
    let instance.error_count = 0
    let instance.failures = []
    let instance.errors = []
    let instance.functionRegister = g:FunctionRegister
    let b:testSuites[a:name] = instance
    return instance
endfunction

function! TestSuite.Setup() dict
    let self.status_string = ""
    let self.run_count = 0
    let self.success_count = 0
    let self.failure_count = 0
    let self.error_count = 0
    let self.failures = []
    let self.errors = []
    call self.functionRegister.AddObject(self, self.name)
endfunction

function! TestSuite.AddUnitTest(unit_test) dict
    call add(self.tests, a:unit_test)
endfunction

function! TestSuite.Run() dict
    call self.Setup()
    for test in self.tests
        call self.functionRegister.AddObject(test, test.name)
        call test.RunInSuite(self)
    endfor
    echo self.PrintResults()
endfunction

function! TestSuite.AddTestResult(test, status, ...)
    let self.run_count = self.run_count + 1
    if a:status == 'F'
        call self.AddFailure(a:test, a:1, a:2)
        let self.failure_count = self.failure_count + 1
    elseif a:status == 'E'
        call self.AddError(a:test, a:1, a:2)
        let self.error_count = self.error_count + 1
    else
        let self.success_count = self.success_count + 1
    endif
    let self.status_string = self.status_string . a:status
    " redraw
    echo a:status
endfunction

function! TestSuite.AddError(test, exception, throwpoint)
    call add(self.errors, [a:test, a:exception, a:throwpoint])
endfunction

function! TestSuite.AddFailure(test, exception, throwpoint)
    call add(self.failures, [a:test, a:exception, a:throwpoint])
endfunction

function! TestSuite.PrintResults() dict
    let sFoo = "Ran " . self.name . " Test Suite\n"
    let sFoo = sFoo . "--Summary-----------------------------------------\n
        \Test count:\t".self.run_count."\n
        \Test Success:\t".self.success_count."\n
        \Test failures:\t".self.failure_count."\n
        \Errors:\t".self.error_count."\n
        \--------------------------------------------------\n\n"
    if len(self.failures) > 0
        let sFoo = sFoo . "FAILURES:\n\n"
        for failure in self.failures
            let sFoo = sFoo . "--------------------------------------------------\n"
            let sFoo = sFoo . "FAILED:\t".failure[0]."\n"
            let sFoo = sFoo . "MSG:\t".failure[1]."\n"
            let sFoo = sFoo . "STACK:\t" . self.functionRegister.ParseThrowpoint(failure[2]) . "\n"
            let sFoo = sFoo . "--------------------------------------------------\n\n"
        endfor
    endif
    if len(self.errors) > 0
        let sFoo = sFoo . "ERRORS:\n\n"
        for error in self.errors
            let sFoo = sFoo . "--------------------------------------------------\n"
            let sFoo = sFoo . "ERROR:\t".error[0]."\n"
            let sFoo = sFoo . "EXCEPTION:\t".error[1]."\n"
            let sFoo = sFoo . "STACK:\t" . self.functionRegister.ParseThrowpoint(error[2]) . "\n"
            let sFoo = sFoo . "--------------------------------------------------\n"
        endfor
    endif
    return sFoo
endfunction


" SelfTest class init {{{1
let s:SelfTest = UnitTest.init("VimUnitSelfTest")

" SelfTest Assert {{{1
function! s:SelfTest.TestAssertEquals() dict  "{{{2
    let sSelf = 'TestAssertEquals'
    call self.AssertEquals(1,1,'Simple test comparing numbers')

    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, [1,2,'Simple test comparing numbers,expect failure'], self, "UnEqual numbers should fail test")

    call self.AssertEquals('str1','str1','Simple test comparing two strings')
    call self.AssertEquals('str1',"str1",'Simple test comparing two strings')
    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, ['str1','str2','Simple test comparing two diffrent strings,expect failure'], self, "Uneqal strings should fail test.")

    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, [123,'123','Simple test comparing number and string containing same number.'], self, 'String and number should not be equal even if they are the same.')
    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, [123,'321','Simple test comparing number and string containing diffrent number'], self, 'Different string and number should not be equal.')

    let arg1 = 1
    let arg2 = 1
    call self.AssertEquals(arg1,arg2,'Simple test comparing two variables containing the same number')
    let arg2 = 2
    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, [arg1,arg2,'Simple test comparing two variables containing diffrent numbers,expect failure'], self, "Different numbers in args should not be equal.")

    let arg1 = "test1"
    let arg2 = "test1"
    call self.AssertEquals(arg1,arg2,'Simple test comparing two variables containing equal strings')
    let arg2 = "test2"
    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, [arg1,arg2,'Simple test comparing two variables containing diffrent strings,expect failure'], self, "Strings as args that are different shouldn't be equal")

    call self.AssertRaises('vimUnitTestFailure', self.AssertEquals, [0, 'a string', 'Simple test comparing 0 to a string, expect failure.'], self, "A string and 0 should not be equal.")

endfunction

function! s:SelfTest.TestAssertNotEquals() dict  "{{{2
    let sSelf = 'TestAssertNotEquals'
    call self.AssertNotEquals(1,2,'Simple test comparing numbers,expect failure')
    call self.AssertRaises('vimUnitTestFailure', self.AssertNotEquals, [1,1,'Simple test comparing numbers,expect failure'], self, '1 and 1 should be equal')

    call self.AssertNotEquals('str1','str2','Simple test comparing two diffrent strings')
    call self.AssertRaises('vimUnitTestFailure', self.AssertNotEquals, ['str1',"str1",'Simple test comparing two strings,expect failure'], self, 'str1 and str1 should not be unequal')

    call self.AssertNotEquals(123,'321','Simple test comparing number and string containing diffrent number')
    call self.AssertNotEquals(123,'123','Simple test comparing number and string containing number')
    let arg1 = 1
    let arg2 = 2
    call self.AssertNotEquals(arg1,arg2,'Simple test comparing two variables containing diffrent numbers')
    let arg2 = 1
    call self.AssertRaises('vimUnitTestFailure', self.AssertNotEquals, [arg1,arg2,'Simple test comparing two variables containing the same number,expect failure'], self, "Numbers 1 and 1 as args should be equal.")

    let arg1 = "test1"
    let arg2 = "test2"
    call self.AssertNotEquals(arg1,arg2,'Simple test comparing two variables containing diffrent strings')
    let arg2 = "test1"
    call self.AssertRaises('vimUnitTestFailure', self.AssertNotEquals, [arg1,arg2,'Simple test comparing two variables containing equal strings,expect failure'], self, "test1 and test1 should be equal, even when args.")
    call self.AssertNotEquals(0, "string", "A string and 0 should not be equal.")
    call self.AssertNotEquals(0, [0,], "A list and an int should not be equal.")
endfunction

function! s:SelfTest.TestAssertTrue() dict  "{{{2
    let sSelf = 'TestAssertTrue'
    call self.AssertTrue(TRUE(),'Simple test Passing function TRUE()')
    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, [FALSE(),'Simple test Passing FALSE(),expect failure'], self, "FALSE() should not be True")

    call self.AssertTrue(1,'Simple test passing 1')
    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, [0, 'Simple test passing 0,expect failure'], self, "The number 0 should not be True")

    let arg1 = 1
    call self.AssertTrue(arg1,'Simple test arg1 = 1')
    let arg1 = 0
    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, [arg1, 'Simple test passing arg1=0,expect failure'], self, 'The number 0 as an arg should not be True')

    
    call self.AssertTrue("test",'Simple test passing string')

    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, ["", 'Simple test passing empty string,expect failure'], self, 'The string "" should not be True')

    let arg1 = 'test'
    call self.AssertTrue(arg1,'Simple test passing arg1 = test')
    let arg1 = ""
    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, [arg1, 'Simple test passing arg1="",expect failure'], self, 'The string "" as an arg should not be True')

    call self.AssertTrue([1,], 'Passing non-empty list')
    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, [[], 'Passing empty list, expect failure'], self, 'The empty list should not be true')
    call self.AssertTrue({"one":1}, 'Passing non-empty dictionary')
    call self.AssertRaises('vimUnitTestFailure', self.AssertTrue, [{}, 'Passing empty dictionary, expect failure'], self, 'The empty dictionary should not be True')
endfunction

function! s:SelfTest.TestAssertFalse() dict  "{{{2
    let sSelf = 'TestAssertFalse'
    call self.AssertFalse(FALSE(), 'Simple test Passing FALSE()')
    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, [TRUE(),'Simple test Passing function TRUE(),expect failure'], self, 'TRUE() should not be False')

    call self.AssertFalse(0,'Simple test passing 0')
    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, [1, 'Simple test passing 1,expect failure'], self, 'Int 1 should not be False')

    let arg1 = 0
    call self.AssertFalse(arg1,'Simple test arg1 = 0')
    let arg1 = 1
    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, [arg1, 'Simple test passing arg1=1,expect failure'], self, 'Int 1 as an arg should not be False')

    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, ["test",'Simple test passing string, expect failure'], self, 'String "test" should not be False')
    call self.AssertFalse("", 'Simple test passing empty string, should pass')

    let arg1 = 'test'
    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, [arg1,'Simple test passing arg1 = test, expect failure'], self, 'string "test" as an arg should not be False')
    let arg1 = ""
    call self.AssertFalse(arg1, 'Simple test passing arg1="", should pass')

    call self.AssertFalse([], 'Empty list should be False')
    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, [[1,],'Passing non-empty list to AssertFalse'], self, 'Non-empty list should not be False')

    call self.AssertFalse({}, 'Empty dict should be False')
    call self.AssertRaises('vimUnitTestFailure', self.AssertFalse, [{'one':"1"},'Passing non-empty dict to AssertFalse'], self, 'Non-empty dict should not be False')
    
endfunction


function! s:SelfTest.TestAssertFail() dict  "{{{2
    let sSelf = 'testAssertFail'
    call self.AssertRaises('vimUnitTestFailure', self.AssertFail, ['Expected failure'], self, 'Asserting a fail should fail.')
endfunction

function! s:ThrowsException(arg1, ...)
    throw 'E554 Exception to be thrown! Arg is '.a:arg1.'. Called with '.string(a:0).' extra args.'
endfunction

function! s:SelfTest.TestAssertRaises() dict "{{{2
    let Fn = function("s:ThrowsException")
    call self.AssertRaises('Exception', Fn, ['arg1', 'arg2'], 'Function should raise exception matching "Exception"')
    call self.AssertRaises('E554', Fn, ['arg1', 'arg2'], 'Function should raise exception matching "E554"')
    call self.AssertRaises('arg1', Fn, ['arg1', 'arg2'], 'Function should raise exception matching "arg1"')
    call self.AssertRaises('Called with 3 extra args', Fn, ['arg1', 'arg2', 'extra', 'another extra'], 'Function should raise exception matching "Called with 3 extra args"')
endfunction

" Functions {{{1

function! s:RunAllTests()
    for suite in values(b:testSuites)
        call suite.Run()
    endfor
endfunction

" Commands {{{1

if !exists(":RunAllTests")
    command RunAllTests :call s:RunAllTests()
endif

" Help (Documentation) installation {{{1
"
" InstallDocumentation {{{2
" ---------------------------------------------------------------------
" Function: <SID>InstallDocumentation(full_name, revision)
"   Install help documentation.
" Arguments:
"   full_name: Full name of this vim pluggin script, including path name.
"   revision:  Revision of the vim script. #version# mark in the document file
"              will be replaced with this string with 'v' prefix.
" Return:
"   1 if new document installed, 0 otherwise.
" Note: Cleaned and generalized by guo-peng Wen
" 
" Source: vimspell.vim s:SpellInstallDocumentation 
"         http://www.vim.org/scripts/script.php?script_id=465  
" ---------------------------------------------------------------------
function! <SID>InstallDocumentation(full_name, revision)
    " Name of the document path based on the system we use:
    if (has("unix"))
        " On UNIX like system, using forward slash:
        let l:slash_char = '/'
        let l:mkdir_cmd  = ':silent !mkdir -p '
    else
        " On M$ system, use backslash. Also mkdir syntax is different.
        " This should only work on W2K and up.
        let l:slash_char = '\'
        let l:mkdir_cmd  = ':silent !mkdir '
    endif

    let l:doc_path = l:slash_char . 'doc'
    let l:doc_home = l:slash_char . '.vim' . l:slash_char . 'doc'

    " Figure out document path based on full name of this script:
    let l:vim_plugin_path = fnamemodify(a:full_name, ':h')
    let l:vim_doc_path    = fnamemodify(a:full_name, ':h:h') . l:doc_path
    if (!(filewritable(l:vim_doc_path) == 2))
        echomsg "Doc path: " . l:vim_doc_path
        execute l:mkdir_cmd . l:vim_doc_path
        if (!(filewritable(l:vim_doc_path) == 2))
            " Try a default configuration in user home:
            let l:vim_doc_path = expand("~") . l:doc_home
            if (!(filewritable(l:vim_doc_path) == 2))
                execute l:mkdir_cmd . l:vim_doc_path
                if (!(filewritable(l:vim_doc_path) == 2))
                    " Put a warning:
                    echomsg "Unable to open documentation directory"
                    echomsg " type :help add-local-help for more informations."
                    return 0
                endif
            endif
        endif
    endif

    " Exit if we have problem to access the document directory:
    if (!isdirectory(l:vim_plugin_path)
        \ || !isdirectory(l:vim_doc_path)
        \ || filewritable(l:vim_doc_path) != 2)
        return 0
    endif

    " Full name of script and documentation file:
    let l:script_name = fnamemodify(a:full_name, ':t')
    let l:doc_name    = fnamemodify(a:full_name, ':t:r') . '.txt'
    let l:plugin_file = l:vim_plugin_path . l:slash_char . l:script_name
    let l:doc_file    = l:vim_doc_path    . l:slash_char . l:doc_name

    " Bail out if document file is still up to date:
    if (filereadable(l:doc_file)  &&
        \ getftime(l:plugin_file) < getftime(l:doc_file))
        return 0
    endif

    " Prepare window position restoring command:
    if (strlen(@%))
        let l:go_back = 'b ' . bufnr("%")
    else
        let l:go_back = 'enew!'
    endif

    " Create a new buffer & read in the pluggin file (me):
    setl nomodeline
    exe 'enew!'
    exe 'r ' . l:plugin_file

    setl modeline
    let l:buf = bufnr("%")
    setl noswapfile modifiable

    norm zR
    norm gg

    " Delete from first line to a line starts with
    " === START_DOC
    1,/^=\{3,}\s\+START_DOC\C/ d

    " Delete from a line starts with
    " === END_DOC
    " to the end of the documents:
    /^=\{3,}\s\+END_DOC\C/,$ d

    " Remove fold marks:
    % s/{\{3}[1-9]/    /

    " Add modeline for help doc: the modeline string is mangled intentionally
    " to avoid it be recognized by VIM:
    call append(line('$'), '')
    call append(line('$'), ' v' . 'im:tw=78:ts=8:ft=help:norl:')

    " Replace revision:
    exe "normal :1s/#version#/ v" . a:revision . "/\<CR>"

    " Save the help document:
    exe 'w! ' . l:doc_file
    exe l:go_back
    exe 'bw ' . l:buf

    " Build help tags:
    exe 'helptags ' . l:vim_doc_path

    return 1
endfunction

" Autmoatically install documentation when script runs {{{2
" This code will check file (self) and install/update documentation included
" at the bottom.
" SOURCE: vimspell.vim, function! <SID>InstallDocumentation
  let s:revision=
    \ substitute("$Revision: 0.1 $",'\$\S*: \([.0-9]\+\) \$','\1','')
  silent! let s:help_install_status =
      \ <SID>InstallDocumentation(expand('<sfile>:p'), s:revision)
  if (s:help_install_status == 1)
      let s:SelfTestSuite = TestSuite.init("SelfTestSuite")
      call s:SelfTestSuite.AddUnitTest(s:SelfTest)
      call s:SelfTestSuite.Run()
      echom expand("<sfile>:t:r") . ' v' . s:revision .
        \ ': Help-documentation installed.'
  endif

    if (g:vimUnitSelfTest == 1)
      let s:SelfTestSuite = TestSuite.init("SelfTestSuite")
      call s:SelfTestSuite.AddUnitTest(s:SelfTest)
      call s:SelfTestSuite.Run()
      echo "Should run test here"
    endif

" Stop sourceing this file, no code after this.
finish

" Documentation {{{1
" Help header {{{2
=== START_DOC
*vimUnit.txt*    A template to create vim and winmanager managed plugins. #version#


    vimUnit. A unit-testing framework targeting vim-scripts

==============================================================================
CONTENT  {{{2                                                *vimUnit-contents*
                                                                 *unit-testing* 
    Installation        : |vimUnit-installation|                  *unittesting* 
    Configuration       : |vimUnit-configuration|
    vimUnit intro       : |vimUnit|
    Requirements        : |vimUnit-requirements|
    vimUnit commands    : |vimUnit-commands|
    Bugs                : |vimUnit-bugs|
    Tips                : |vimUnit-tips|
    Todo list           : |vimUnit-todo|
    Change log          : |vimUnit-cahnge-log|

==============================================================================
1. vimUnit Installation {{{2                            *vimUnit-installation*

    TODO: Write documentation, Installation
    
    Copy the file vimUnit.vim to your ftplugin directory. That would normaly 
    be ~/.vim/ftplugin/ on *nix and $VIM/vimfiles/ftplugin/ on MS-Windows.

    The next time you start vim (or gvim) after you have installed the plugin 
    this documentation si suposed to automaticaly be installed.
    
==============================================================================
1.1 vimUnit Configuration {{{2                         *vimUnit-configuration*
                                                            |vimUnit-content|
                                                            
                                                            *vimUnit-AutoRun*
                                                                  *VUAutoRun*
    To ease testing of scripts there is a AutoRun (VUAutoRun()) routine. When 
    called from the commandline or a mapping of your preference it takes the 
    curser position in the file and figure out if your inside a function 
    starting with 'Test'. If you are the file your in will be saved and sourced.
    Then the function will be called, and you get a printout of the statistics.
    So placing the cursor on call (in a vim file) inside the function:
    
        function! TestThis()
            self.AssertTrue(TRUE(),'Simple test of true')   
        endfunction
        
    And calling:
        :self.VUAutoRun()
        
    Will give you the statistics.

    
                                                           *vimUnit-verbosity*
    When we are running test cases to much output could be annoying. turn msg 
    output off in your vimrc file with:
        let g:vimUnitVerbosity = 0
    Default value is 1.
                                                            *vimUnit-selftest*
    vimUnit has code to test that it work as expected. This code will run the 
    first time vim is running after you installed vimUnit. After that it will 
    only run again if there is changes to the vimUnit.vim file. If you want 
    vimUnit to do a self-test every time it is loaded (sourced) you should add
    this line to your vimrc file:
        let g:vimUnitSelfTest = 1

==============================================================================
1.1 vimUnit Requirements {{{2                           *vimUnit-requirements*
                                                            |vimUnit-content|
    TODO: Write documentation, Requirements
    
    Just a working vim environment
    
==============================================================================
2. vimUnit Intro {{{2                                 *VU* *VimUnit* *vimUnit*
                                                            |vimUnit-content|
    TODO: Write documentation, Intro
    
    The phillosophy behind test-first driven development is simple. 
    When you consider to write some code, you normaly have an idea of what you
    want the code to do. So, instead of just thinking of what your code should 
    do try to write down a test case formalising your thoughts. When you have 
    a test case you start writing the code to make the test case complete 
    successfully. If your work discover problem areas, error conditions or
    suche write a test to make shure your code handels it. And will continue 
    to handel it the next time you make some changes. Writing code, also test
    code, is hard (but fun) work.
    Ex:
        "First we have an ide of how our function Cube should work
        func! TestCaseCube()
            self.AssertEquals(<SID>Cube(1),1,'Trying to cube 1)')
            self.AssertEquals(<SID>Cube(2),2*2*2,'Trying to cube 2)')
            self.AssertEquals(<SID>Cube(3),3*3*3,'Trying to cube 3)')
            "Take a look at the statistics
            self.PrintStatistics()
        endfunc
        "We write ouer Cube Function
        func! <SID>Cube(arg1)
            let nFoo = arg1*arg1*arg1
            return nFoo
        endfunc
        
        "Enter commands to run the test
        "Source the current file (in current window)
        :so %
        "call the TestCase
        :call TestCaseCube()

    That's it If we get errors we must investigate. We should make test's 
    discovering how our function handels obvious error conditions. How about
    adding this line to our TestCase:
        self.AssertEquals(<SID>Cube('tre'),3*3*3,'Trying to pass a string')
        
    Do we get a nice error message or does our script grind to a halt?
    Should we add a test in Cube that ensure valide arguments?
        if type(arg1) == 0
            ...
        else
            echomsg "ERROR: You passed a string to the Cube function."
        endif
        
    After some itterations and test writings we should feel confident that our
    Cube function works like expected, and will continue to do so even if we 
    make changes to it.

==============================================================================
3. vimUnit Commands {{{2                                    *vimUnit-commands*
                                                            |vimUnit-content|
    TODO: Write documentation, Commands
    
    When you se ... at the end of the argument list you may optionaly provide 
    a message string.
    
    AssertEquals(ar1, arg2, ...)
        VUAssert that arg1 is euqal in content to arg2.
    AssertTrue(arg1, ...)
        VUAssert that arg1 is true.
    AssertFalse(arg1, ...)
        VUAssert that arg1 is false.
    AssertFail(...)
        Log a userdefined failure.
        


    RunnerInit()
        TODO:
    VURunnerStartSuite(caller)
        TODO:
    VURunnerStopSuite(caller)
        TODO:
==============================================================================
4. vimUnit Bugs {{{2                                            *vimUnit-bugs*
                                                            |vimUnit-content|
    TODO: Write documentation, Bugs
    
    Bugs, what bugs..;o)
    
==============================================================================
5. vimUnit Tips {{{2                                            *vimUnit-tips*
                                                            |vimUnit-content|
    TODO: Write documentation, Tips
    
==============================================================================
6. vimUnit Todo list {{{2                                       *vimUnit-todo*   
                                                            |vimUnit-content|
    TODO: Write more documentation
    TODO: Cleanup function header comments  

    TODO: TestResult methodes are not implemented       {{{3
        TestResultAddError(test, ...)
        TestResultAddFailure(test, ...)
        TestResultAddListener(listener, ...)
        TestResultCloneListener()
        TestResultErrorCount()
        TestResultErrors()
        TestResultFailureCount()
        TestResultFailures()
        TestResultRemoveListener(listener, ...)
        TestResultRun(testCase, ...)
        TestResultRunCount()
        TestResultShouldStop()
        TestResultStartTest(test)
        TestResultStop()
        TestResultWasSuccessful()
        }}}
==============================================================================
7. vimUnit Change log  {{{2                               *vimUnit-change-log*
                                                            |vimUnit-content|
Developer reference: (breake up mail address)
---------------------------------------------
SF = Staale Flock, staale -- lexholm .. no

------------------------------------------------------------------------------
By  Date        Description, if version nr changes place it first.
------------------------------------------------------------------------------
SF  8 Nov 2004  0.1 Initial uppload
==============================================================================
" Need the next formating line inside the help document
" vim: ts=4 sw=4 tw=78: 
=== END_DOC
" vim: ts=4 sw=4 tw=78 foldmethod=marker
