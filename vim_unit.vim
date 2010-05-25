" Normally za or zR will open the folds- zM will close them all.
" File header {{{1
" --------------------------------------------------------------
"  FILE:            vimUnit.vim
"  AUTHOR:          Staale Flock, Staale -- lexholm .. no
"  MODIFIED:        Ben Best
"  VERSION:         0.2
"  LASTMODIFIED:    24 May 2010
"
"  PURPOSE:
"		To provide vim scripts with a simple unit testing framework and tools.
"		The framework and tools should resemble JUnit's interface definitions
"		to ease usage of both frameworks (and others based on JUnit). 
"		Obviously vim scripts are not java so I will only try to implement the
"		stuff useful to vim scripts. As a first milestone I think the 
"		junit.Assert and junit.TestResult classes to get a vim-script
"		unit-testing environment going. Modified to use an object instead of
"		lengthy VUAssert calls.
"		
"  WHY:
" 		Well, I have been working on some vim-scripts and read a lot of them
" 		the last two weeks and I really, really miss my unit-test (and
" 		mock-object, but that is fare fetched I think..:O) tools to get my own
" 		stuff of the ground (and making modifications to your's).
" 		
"  THOUGHTS:
"		Writing unit-test code against a UI environment is often very difficult 
"		or demanding to creative solutions to be productive. We would like to 
"		have a mock-object framework to go with the unit-testing framework.
"		
"  INSTALLATION:
"  		Place this file in your plugin directory (~/.vim/ftplugin/)
"  		When you start vim again and open a vim file for editing you should
"  		get a message that vimUnit has installed its documentation.
"  		To get you started you could try :h vimUnit
"  		
"  TIPS:
"  		Documentation (when written..:o) is found at the bottom of this file. 
"  		Thanks to code from vimspell.vim it should be self-installing the first
"  		time this module is loaded
"
"  		If your new to test-first principles and thinking you should start
"  		with the article: 
"  			http://junit.sourceforge.net/doc/testinfected/testing.htm
"  		And then surf the web on these locations:
"  			http://www.junit.org/
"  			http://xprogramming.com/
"  			http://www.extremeprogramming.org/
" 
"  NOTE:
"		8 Nov 2004 (v 0.1) This is my initial upload. The module is fare 
"		from finished. But as I could do with some input from other vim users
"		So I have chosen to let people know I'm working on it. 
"
"		To be conform with vim-script naming conventions functions are
"		prepended with VU (VimUnit). So stuff you would normaly would call 
"		VUAssert are called VUAssert, TestRunner* are called VURunner and so on.
"		Global variables starts with vimUnit*
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
"	Variables Global{{{2
"	Global variables might be set in vimrc

if !exists('g:vimUnitSelfTest')
"	1 ==> Always run self test when loaded
"	0 ==> Do not run self test when loaded. SelfTest will however run if the
"	file is modified since the documentation was installed.
	let g:vimUnitSelfTest = 1
endif

if !exists('g:vimUnitVerbosity')
	"At the moment there is just 0 (quiet) and 1(verbose)
	let g:vimUnitVerbosity = 1
endif

"   Main UnitTest object definition{{{2
if !exists('UnitTest')
    let UnitTest = {}
    let UnitTest.testRunCount = 0
    let UnitTest.testRunSuccessCount = 0
	let UnitTest.testRunFailureCount = 0
	let UnitTest.testRunExpectedFailuresCount = 0
    let UnitTest.name = 'OVERWRITE ME'
endif




" VUAssert {{{1
" -----------------------------------------
" FUNCTION:	TODO:
" PURPOSE:
"	Just a reminder that a function is not (fully) implemented.
" ARGUMENTS:
"	funcName:	The name of the calling function
" RETURNS:
"	false
" -----------------------------------------
function! UnitTest.TODO(funcName) dict	"{{{2
	echomsg '[TODO] '.a:funcName
	return FALSE()
endfunction

" ---------------------------------------------------------------------
" FUNCTION:	AssertEquals
" PURPOSE:
"	Compare arguments
" ARGUMENTS:
" 	arg1 : Argument to be tested.
" 	arg2 : Argument to test against.
"	...  : Optional message.
" RETURNS:
"	0 if arg1 == arg2
"	1 if arg1 != arg2
" ---------------------------------------------------------------------
function! UnitTest.AssertEquals(arg1, arg2, ...) dict	"{{{2
	let self.testRunCount = self.testRunCount + 1
	if a:arg1 == a:arg2
		let self.testRunSuccessCount = self.testRunSuccessCount + 1
		let bFoo = TRUE()
	else
		let self.testRunFailureCount = self.testRunFailureCount + 1
		let bFoo = FALSE()
		call <SID>MsgSink('FAILED: AssertEquals','arg1='.a:arg1.'!='.a:arg2.' MSG:'.a:1)
	endif
	return bFoo
endfunction
" ---------------------------------------------------------------------
" FUNCTION:	AssertNotEquals
" PURPOSE:
"	Compare arguments
" ARGUMENTS:
" 	arg1 : Argument to be tested.
" 	arg2 : Argument to test against.
"	...  : Optional message.
" RETURNS:
"	1 if arg1 == arg2
"	0 if arg1 != arg2
" ---------------------------------------------------------------------
function! UnitTest.AssertNotEquals(arg1, arg2, ...) dict	"{{{2
	let self.testRunCount = self.testRunCount + 1
	if a:arg1 != a:arg2
		let self.testRunSuccessCount = self.testRunSuccessCount + 1
		let bFoo = TRUE()
	else
		let self.testRunFailureCount = self.testRunFailureCount + 1
		let bFoo = FALSE()
		call <SID>MsgSink('FAILED: AssertNotEquals','arg1='.a:arg1.'=='.a:arg2.' MSG: '.a:1)
	endif
	return bFoo
endfunction
" ---------------------------------------------------------------------
" FUNCTION:	AssertTrue
" PURPOSE:
" 	Check that the passed argument validates to true
" ARGUMENTS:
" 	arg1: Should validate to TRUE() == (1==1)
" 	... : Optional message placeholder.
" RETURNS:
" 	TRUE() if true and
" 	FALSE() if false
" ---------------------------------------------------------------------
function! UnitTest.AssertTrue(arg1, ...) dict	"{{{2
	let self.testRunCount = self.testRunCount + 1
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

    if bFoo == TRUE()
		let self.testRunSuccessCount = self.testRunSuccessCount + 1
    else
		let self.testRunFailureCount = self.testRunFailureCount + 1
		"TODO: What if a:1 does not exists?
		call <SID>MsgSink('FAILED: AssertTrue','arg1='.string(a:arg1).'!=TRUE MSG: '.a:1)
    endif

	return bFoo
endfunction
" ---------------------------------------------------------------------
" FUNCTION:	 AssertFalse
" PURPOSE:
"	Test if the argument equals false
" ARGUMENTS:
"	arg1:	Contains something that will be evaluated to true or false
" RETURNS:
"	0 if true
"	1 if false
" ---------------------------------------------------------------------
function! UnitTest.AssertFalse(arg1, ...) dict	"{{{2
	let self.testRunCount = self.testRunCount + 1
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

    if bFoo == TRUE()
		let self.testRunSuccessCount = self.testRunSuccessCount + 1
    else
		let self.testRunFailureCount = self.testRunFailureCount + 1
		"TODO: What if a:1 does not exists?
		call <SID>MsgSink('FAILED: AssertFalse','arg1='.string(a:arg1).'!=FALSE MSG: '.a:1)
    endif

	return bFoo
endfunction

" VUAssert that the arg1 is initialized (is not null)
" Is this situation possible in vim script?
function! UnitTest.AssertNotNull(arg1, ...) dict	"{{{2
	"NOTE: I do not think we will have a situation in a vim-script where we
	"can pass a variable containing a null as I understand it that is a
	"uninitiated variable.
	"
	"vim will give a warning (error) msg when we try to do this.
	"
	"BUT: We can have situations where we try to do this. Especialy if we are
	"using on-the-fly variable names. :help curly-braces-names
	"
	let self.testRunCount = self.testRunCount + 1
	if exists(a:arg1)
		let self.testRunSuccessCount = self.testRunSuccessCount + 1
		let bFoo = TRUE()
	else
		let self.testRunFailureCount = self.testRunFailureCount + 1
		let bFoo = FALSE()
		call <SID>MsgSink('FAILED: AssertNotNull','arg1: Does not exist')
	endif
	return bFoo	
endfunction

"Fail a test with no arguments
function! UnitTest.AssertFail(...) dict	"{{{2
	let self.testRunCount = self.testRunCount + 1
	let self.testRunFailureCount = self.testRunFailureCount + 1
	call <SID>MsgSink('FAILED: AssertFail','')
	return FALSE()
endfunction

" VURunner {{{1
" ----------------------------------------- {{{2
" FUNCTION:	RunTests
" PURPOSE:
"	Run tests contained in the current object
" ARGUMENTS:
"	None
" RETURNS:
"	None
" -----------------------------------------
function! UnitTest.RunTests() dict
		call self.RunnerInit()
		echomsg "Running: ".self.name
        for key in keys(self)
            if strpart(key, 0, 4) == 'Test' && type(self[key]) == type(function("tr"))
                call self[key]()
            endif
        endfor
		call self.PrintStatistics(self.name)
endfunction

" ----------------------------------------- {{{2
" FUNCTION:	PrintStatistics
" PURPOSE:
"	Print statistics about test's
" ARGUMENTS:
"	None
" RETURNS:
"	String containing statistics
" -----------------------------------------
function! UnitTest.PrintStatistics(caller,...) dict
	if exists('a:caller')
		let sFoo = "----- ".a:caller."---------------------------------------------\n"
	else
		let sFoo ="--------------------------------------------------\n"
	endif
	if exists('a:1') && a:1 != ''
		let sFoo = sFoo."MSG: ".a:1
	endif
	let sFoo = sFoo."Test count:\t".self.testRunCount."\nTest Success:\t".self.testRunSuccessCount."\nTest failures:\t".self.testRunFailureCount."\nExpected failures:\t".self.testRunExpectedFailuresCount
	let sFoo = sFoo."\n--------------------------------------------------\n"
	"
	echo sFoo
	return sFoo
endfunction

" ----------------------------------------- {{{2
" FUNCTION:	RunnerInit
" PURPOSE:
"	Reset statistics to zero
" ARGUMENTS:
"	None
" RETURNS:
"	None
" -----------------------------------------
function! UnitTest.RunnerInit() dict
    echomsg "CLEARING: statistics"
	let self.testRunCount = 0
	let self.testRunFailureCount = 0
	let self.testRunSuccessCount = 0
	let self.testRunExpectedFailuresCount = 0
endfunction

" -----------------------------------------
" FUNCTION:	 ExpectFailure
" PURPOSE:
"	Notify the runner that the next test is supposed to fail
" ARGUMENTS:
"
" RETURNS:
"
" -----------------------------------------
function! UnitTest.ExpectFailure(caller,...) dict  "{{{2
	"TODO: Add msg trace
	let self.testRunExpectedFailuresCount = self.testRunExpectedFailuresCount + 1
endfunction

function! <sid>MsgSink(caller,msg)  "{{{2
	if g:vimUnitVerbosity > 0
		echo a:caller.': '.a:msg
	endif
endfunction

"staale - GetCurrentFunctionName()
"Extract the function name the cursor is inside
function! <SID>GetCurrentFunctionName()		"{{{2
	"call s:FindBlock('\s*fu\%[nction]\>!\=\s.*(\%([^)]*)\|\%(\n\s*\\[^)]*\)*\n)\)', '', '', '^\s*endf\%[unction]', 0)
	"bWn ==> b=Search backward, W=Don't wrap around end of file,n=Do not move cursor.
	let nTop = searchpair('^\s*fu\%[nction]\%[!]\ .*','','^\s*endf\%[unction].*','bWn')
	let sLine = getline(nTop)
	return sLine
endfunction

function! <SID>ExtractFunctionName(strLine)		"{{{2
" This used to be part of the GetCurrentFunctionName() routine
" But to make as much as possible of the code testable we have to isolate code
" that do any kind of buffer or window interaction.
	let lStart = matchend(a:strLine,'\s*fu\%[nction]\%[!]\s')
	let sFoo = matchstr(a:strLine,".*(",lStart)
	let sFuncName =strpart(sFoo ,0,strlen(sFoo)-1)
	return sFuncName
endfunction


"function VUAutoRun {{{2
" We have to make a check so we can AutoRun vimUnit.vim itself
if !exists('s:vimUnitAutoRun')
	let s:vimUnitAutoRun = 0
endif
if s:vimUnitAutoRun == 0
" function! VUAutoRun()
" 	"NOTE:If you change thsi code you must manualy source the file!
"
" 	let s:vimUnitAutoRun = 1
" 	"Prevent VimUnit from runing selftest if we are testing VimUnit.vim
" 	let b:currentVimSelfTest = g:vimUnitSelfTest
" 	let g:vimUnitSelfTest = 0
" 	"Locate function line on line with or above current line
" 	let sFoo = <SID>ExtractFunctionName(<SID>GetCurrentFunctionName())
" 	if match(sFoo,'^Test') > -1
" 		"We found the function name and it starts with Test so we source the
" 		"file and self.RunTests to run the test
" 		exe "w|so %"
" 		if exists( '*'.sFoo)
" 			self.RunTests(sFoo)
" 		else
" 			call confirm ("ERROR: VUAutoRunner. Function name: ".sFoo." Could not be found by function exists(".sFoo.")")
" 		endif
" 	else
" 		"
" 		echo "NOTE: Found function name: ".sFoo." Does not start with Test.So we will not run it automaticaly"
" 	endif
" 	let s:vimUnitAutoRun = 0
" 	let g:vimUnitSelfTest = b:currentVimSelfTest
" endfunction
endif

" SelfTest class init {{{1
let s:SelfTest = copy(UnitTest)
let s:SelfTest.name = "VimUnitSelfTestSuite"

" SelfTest Assert {{{1
function! s:SelfTest.TestAssertEquals() dict  "{{{2
	let sSelf = 'TestAssertEquals'
	call self.AssertEquals(1,1,'Simple test comparing numbers')
	call self.ExpectFailure(sSelf,'AssertEquals(1,2,"")')
	call self.AssertEquals(1,2,'Simple test comparing numbers,expect failure')

	call self.AssertEquals('str1','str1','Simple test comparing two strings')
	call self.AssertEquals('str1',"str1",'Simple test comparing two strings')
	call self.ExpectFailure(sSelf,"AssertEquals(\'str1\',\"str1\",\"\")")
	call self.AssertEquals('str1','str2','Simple test comparing two diffrent strings,expect failure')

	call self.AssertEquals(123,'123','Simple test comparing number and string containing number')
	call self.ExpectFailure(sSelf,"AssertEquals(123,'321',\"\")")
	call self.AssertEquals(123,'321','Simple test comparing number and string containing diffrent number,expect failure')

	let arg1 = 1
	let arg2 = 1
	call self.AssertEquals(arg1,arg2,'Simple test comparing two variables containing the same number')
	let arg2 = 2
	call self.ExpectFailure(sSelf,'AssertEquals(arg1=1,arg2=2,"")')
	call self.AssertEquals(arg1,arg2,'Simple test comparing two variables containing diffrent numbers,expect failure')

	let arg1 = "test1"
	let arg2 = "test1"
	call self.AssertEquals(arg1,arg2,'Simple test comparing two variables containing equal strings')
	let arg2 = "test2"
	call self.ExpectFailure(sSelf,'AssertEquals(arg1=test1,arg2=test2,"")')
	call self.AssertEquals(arg1,arg2,'Simple test comparing two variables containing diffrent strings,expect failure')

"	self.AssertEquals(%%%,%%%,"Simple test comparing %%%')
"	self.ExpectFailure(sSelf,'AssertEquals(%%%,%%%,"")')
"	self.AssertEquals(%%%,%%%,"Simple test comparing %%%,expect failure')
endfunction

function! s:SelfTest.TestAssertNotEquals() dict  "{{{2
	let sSelf = 'TestAssertNotEquals'
	call self.AssertNotEquals(1,2,'Simple test comparing numbers,expect failure')
	call self.ExpectFailure(sSelf,'AssertNotEquals(1,1,"")')
	call self.AssertNotEquals(1,1,'Simple test comparing numbers,expect failure')

	call self.AssertNotEquals('str1','str2','Simple test comparing two diffrent strings')
	call self.ExpectFailure(sSelf,"AssertNotEquals(\'str1\',\"str1\",\"\")")
	call self.AssertNotEquals('str1',"str1",'Simple test comparing two strings,expect failure')

	call self.AssertNotEquals(123,'321','Simple test comparing number and string containing diffrent number')
	call self.ExpectFailure(sSelf,"AssertNotEquals(123,'123',\"\")")
	call self.AssertNotEquals(123,'123','Simple test comparing number and string containing number,expect failure')
	
	let arg1 = 1
	let arg2 = 2
	call self.AssertNotEquals(arg1,arg2,'Simple test comparing two variables containing diffrent numbers')
	call self.ExpectFailure(sSelf,'AssertNotEquals(arg1=1,arg2=1,"")')
	let arg2 = 1
	call self.AssertNotEquals(arg1,arg2,'Simple test comparing two variables containing the same number,expect failure')

	let arg1 = "test1"
	let arg2 = "test2"
	call self.AssertNotEquals(arg1,arg2,'Simple test comparing two variables containing diffrent strings')
	let arg2 = "test1"
	call self.AssertNotEquals(arg1,arg2,'Simple test comparing two variables containing equal strings,expect failure')
	call self.ExpectFailure(sSelf,'AssertNotEquals(arg1=test1,arg2=test1,"")')

"	self.AssertEquals(%%%,%%%,"Simple test comparing %%%')
"	self.ExpectFailure(sSelf,'AssertEquals(%%%,%%%,"")')
"	self.AssertEquals(%%%,%%%,"Simple test comparing %%%,expect failure')
endfunction

function! s:SelfTest.TestAssertTrue() dict  "{{{2
	let sSelf = 'TestAssertTrue'
	call self.AssertTrue(TRUE(),'Simple test Passing function TRUE()')
	call self.ExpectFailure(sSelf,'AssertTrue(FALSE(),"")')
	call self.AssertTrue(FALSE(), 'Simple test Passing FALSE(),expect failure')

	call self.AssertTrue(1,'Simple test passing 1')
	call self.ExpectFailure(sSelf,'AssertTrue(0,"")')
	call self.AssertTrue(0, 'Simple test passing 0,expect failure')

	let arg1 = 1
	call self.AssertTrue(arg1,'Simple test arg1 = 1')
	call self.ExpectFailure(sSelf,'AssertTrue(arg1=0,"")')
	let arg1 = 0
	call self.AssertTrue(arg1, 'Simple test passing arg1=0,expect failure')	

	
	call self.AssertTrue("test",'Simple test passing string')

	call self.ExpectFailure(sSelf,'AssertTrue("","")')
	call self.AssertTrue("", 'Simple test passing empty string,expect failure')

	let arg1 = 'test'
	call self.AssertTrue(arg1,'Simple test passing arg1 = test')
    let arg1 = ""
	call self.ExpectFailure(sSelf,'AssertTrue(arg1="","")')
	call self.AssertTrue(arg1, 'Simple test passing arg1="",expect failure')

    call self.AssertTrue([1,], 'Passing non-empty list')
	call self.ExpectFailure(sSelf,'AssertTrue(arg1=[])')
    call self.AssertTrue([], 'Passing empty list, expect failure')
    call self.AssertTrue({"one":1}, 'Passing non-empty dictionary')
	" call self.ExpectFailure(sSelf,'AssertTrue(arg1={})')
    " call self.AssertTrue({}, 'Passing empty dictionary, expect failure')

"	self.AssertTrue(%%%,'Simple test %%%')
"	self.ExpectFailure(sSelf,'AssertTrue(%%%,"")')
"	self.AssertTrue(%%%, 'Simple test %%%,expect failure')	
	
endfunction

function! s:SelfTest.TestAssertFalse() dict  "{{{2
	let sSelf = 'TestAssertFalse'
	call self.AssertFalse(FALSE(), 'Simple test Passing FALSE()')
	call self.ExpectFailure(sSelf,'AssertFalse(TRUE(),"")')
	call self.AssertFalse(TRUE(),'Simple test Passing function TRUE(),expect failure')

	call self.AssertFalse(0,'Simple test passing 0')
	call self.ExpectFailure(sSelf,'AssertFalse(1,"")')
	call self.AssertFalse(1, 'Simple test passing 1,expect failure')

	let arg1 = 0
	call self.AssertFalse(arg1,'Simple test arg1 = 0')
	call self.ExpectFailure(sSelf,'AssertFalse(arg1=1,"")')
	let arg1 = 1
	call self.AssertFalse(arg1, 'Simple test passing arg1=1,expect failure')

	call self.ExpectFailure(sSelf,'AssertFalse("test","")')
	call self.AssertFalse("test",'Simple test passing string, expect failure')
	call self.AssertFalse("", 'Simple test passing empty string, should pass')

	call self.ExpectFailure(sSelf,'AssertFalse(arg1="test","")')
	let arg1 = 'test'
	call self.AssertFalse(arg1,'Simple test passing arg1 = test, expect failure')
    let arg1 = ""
	call self.AssertFalse(arg1, 'Simple test passing arg1="", should pass')
	
endfunction
function! s:SelfTest.TestAssertNotNull() dict "{{{2
	"NOTE: I do not think we will have a situation in a vim-script where we
	"can pass a variable containing a null as I understand it that is a
	"uninitiated variable.
	"
	"vim will give a warning (error) msg when we try to do this.
	"
	"BUT: We can have situations where we try to do this. Especeialy if we are
	"using on-the-fly variable names. :help curly-braces-names
	"
	let sSelf = 'TestAssertNotNull'
	call self.ExpectFailure(sSelf,'Trying to pass a unlet variable')
	try
		let sTest = ""
		unlet sTest
		call self.AssertNotNull(sTest,'Trying to pass a uninitiated variable')
	catch
		call self.AssertFail('Trying to pass a uninitiated variable')
	endtry
	
	call self.ExpectFailure(sSelf,'Trying to pass a uninitiated variable')
	try
		call self.AssertNotNull(sTest2,'Trying to pass a uninitated variable sTest2')
	catch
		call self.AssertFail('Trying to pass a uninitated variable sTest2')
	endtry
	
endfunction



function! s:SelfTest.TestAssertFail() dict  "{{{2
	let sSelf = 'testAssertFail'
	call self.ExpectFailure(sSelf,'Calling AssertFail()')
	call self.AssertFail('Expected failure')
endfunction


function! s:SelfTest.TestExtractFunctionName() dict "{{{1
	let sSelf = 'TestExtractFunctionName'
	"Testing leagal function declarations
	"NOTE: The markers in the test creates a bit of cunfusion
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName('func TestFunction()'),'straight function declaration')
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName('func! TestFunction()'),'func with !')
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName(' func TestFunction()'),'space before func')
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName('		func TestFunction()'),'Two embeded tabs before func') "Two embeded tabs
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName('func TestFunction()	"{{{3'),'Declaration with folding marker in comment' )
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName('   func TestFunction()	"{{{3'),'Declaration starting with space and ending with commented folding marker')
	let sFoo = self.AssertEquals('TestFunction',<SID>ExtractFunctionName('func TestFunction(arg1, funcarg1, ..)'),'arguments contain func')
endfunction	"}}}


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
	  call s:SelfTest.RunTests()
      echom expand("<sfile>:t:r") . ' v' . s:revision .
		\ ': Help-documentation installed.'
  endif

	if (g:vimUnitSelfTest == 1)
	  call s:SelfTest.RunTests()
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
	AssertNotNull(arg1, ...)
		VUAssert that arg1 is initiated.
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

	TODO: TestResult methodes are not implemented 		{{{3
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
By	Date		Description, if version nr changes place it first.
------------------------------------------------------------------------------
SF	8 Nov 2004	0.1	Initial uppload
==============================================================================
" Need the next formating line inside the help document
" vim: ts=4 sw=4 tw=78: 
=== END_DOC
" vim: ts=4 sw=4 tw=78 foldmethod=marker
