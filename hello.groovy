#!/bin/groovy

class Example {
   static void main(String[] args) {
      // Using a simple println statement to print output to the console
      println('Hello World');

      def age = 40
      println("Age++ = " + age++)
      println("++Age = " + ++age)
      println("Age-- = " + age--)
      println("--Age = " + --age)

      def name = "Faiz"
      println('My name is ${name} \n') //single line takes everything literally, except the few like next line
      println("My name is ${name} \n")  //#works as usual

      def multiline = '''Hi , 
      just checking, for multi-line
      if working '''
      println(multiline)

      println("3rd index of name  = " + name[3])
      println("index number of i in name = " + name.indexOf('i'))

      def rep = "check the string " * 2
      println(rep)
      println( rep - "check")
      println(rep.split(' '))      
      println(rep.toList())

      //new feature

      //comment git
   }
}

 