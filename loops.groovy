class loops {
    static main(args) {
        int count=0;
        //check while
        while(count<5)
        {
            println(count);
            count++;
        }
        for(int i = 0;i<5;i++) 
        {
	     println("for: " + i);
        }

        //"for in" type loop
        int[] array = [0,1,2,3]; 
        for(int j in array)
        {
            println("for in : " + j)
        }

    }
}

