#include <stdio.h>
#include <stdlib.h>
#include <objc/objc.h>
#include <objc/runtime.h>

int main(){

  int class_size = sizeof(Class);
  int class_count = objc_getClassList(NULL, 0);

  printf("size of Class is %ubytes\n", class_size);  
  printf("number of classes is %u\n", class_count);

  Class* classes = malloc(class_size * class_count);
  int return_count = objc_getClassList(classes, class_count);

  printf("getClassList returned %u classes\n", return_count);

  for(int i=0;i < return_count;i++){
    const char* class_name = class_getName(*classes);
    printf("class %u is named %s\n", i, class_name);
    ++classes;    
  }
  free(classes - return_count);

  Class nsstring_class = objc_getClass("NSString");
  if(nsstring_class != 0){
    const char* class_name = class_getName(nsstring_class);
    printf("class named %s was found\n", class_name);
  }

  int nsstring_size = class_getInstanceSize(nsstring_class);
  printf("NSString instances are %ubytes long \n", nsstring_size);

  Class nsstring_meta_class = object_getClass((id)nsstring_class);
  int number_of_class_methods = 0;
  Method* nsstring_class_methods = class_copyMethodList(nsstring_meta_class, &number_of_class_methods);

  printf("it has %u class methods\n", number_of_class_methods);

  for(int i=0; i < number_of_class_methods; i++){
    struct objc_method_description foo = *method_getDescription(*nsstring_class_methods);
    const char* selector_name = sel_getName(foo.name);

    int number_of_args = method_getNumberOfArguments(*nsstring_class_methods);

    printf("method %3u is named %s\n", i, selector_name);
    printf("it takes %u arguments:\n", number_of_args);

    for(unsigned int x=0; x < number_of_args; x++){
      const char* argument_type_string = method_copyArgumentType(*nsstring_class_methods, x);
      printf("%u is of type %s\n", x, argument_type_string);
    }

    ++nsstring_class_methods;
  }

  return 0;
}
