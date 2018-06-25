---
title: QLExpress使用简介
date: 2018-01-02 19:01:54
categories: "规则引擎"
tags:
    - 规则引擎
    - QLExpress
---
## 1. 背景
运营人员在活动投放时通常会根据某个用户的多个标签进行与或非 IN Contains Between And > < ==  等决定是否给该用户投放相应的活动。后台为了实现该功能就需要使用规则引擎。提到规则引擎，可能会想到Drools甚至是antlr，Groovy,这几个虽然功能都很强大，但是使用起来还是不太方便，经过 Google 之后发现了QLExpress，一个阿里开源的轻量级的类java语法规则引擎，作为一个嵌入式规则引擎在业务系统中使用，支持标准的JAVA语法，还可以支持自定义操作符号、操作符号重载、函数定义、宏定义、数据延迟加载等。
<!-- more -->
## 2. QLExpress简介
### 2.0 功能框图
![](/images/20171026112204027.jpeg)
### 2.1 基本语法
* 支持 +,-,*,/,<,>,<=,>=,==,!=,<>【等同于!=】,%,mod【取模等同于%】,++,--,
* in【类似sql】,like【sql语法】,&&,||,!,等操作符
* 支持for，break、continue、if then else 等标准的程序控制逻辑
```
n=10;
for(sum=0,i=0;i<n;i++){
    sum=sum+i;
}
return sum;
//逻辑三元操作
a=1;
b=2;
max = a>b?a:b;
```
* 关于对象，类，属性，方法的调用

```Java
import com.ql.util.express.test.OrderQuery;
//系统自动会import java.lang.*,import java.util.*;


query = new OrderQuery();//创建class实例,会根据classLoader信息，自动补全类路径
query.setCreateDate(new Date());//设置属性
query.buyer = "张三";//调用属性,默认会转化为setBuyer("张三")
result = bizOrderDAO.query(query);//调用bean对象的方法
System.out.println(result.getId());//静态方法

 ```

* 自定义操作符号：addOperatorWithAlias+addOperator+addFunction

```java

runner.addOperatorWithAlias("如果", "if",null);
runner.addOperatorWithAlias("则", "then",null);
runner.addOperatorWithAlias("否则", "else",null);

exp = "如果  (如果 1==2 则 false 否则 true) 则 {2+2;} 否则 {20 + 20;}";
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.execute(exp,nil,null,false,false,null);


//定义一个继承自com.ql.util.express.Operator的操作符
public class JoinOperator extends Operator{
	public Object executeInner(Object[] list) throws Exception {
		Object opdata1 = list[0];
		Object opdata2 = list[1];
		if(opdata1 instanceof java.util.List){
			((java.util.List)opdata1).add(opdata2);
			return opdata1;
		}else{
			java.util.List result = new java.util.ArrayList();
			result.add(opdata1);
			result.add(opdata2);
			return result;
		}
	}
}

ExpressRunner runner = new ExpressRunner();
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.addOperator("join",new JoinOperator());
Object r = runner.execute("1 join 2 join 3", context, null, false, false);
System.out.println(r);
//返回结果  [1, 2, 3]


class GroupOperator extends Operator {
	public GroupOperator(String aName) {
		this.name= aName;
	}
	public Object executeInner(Object[] list)throws Exception {
		Object result = Integer.valueOf(0);
		for (int i = 0; i < list.length; i++) {
			result = OperatorOfNumber.add(result, list[i],false);//根据list[i]类型（string,number等）做加法
		}
		return result;
	}
}

runner.addFunction("group", new GroupOperator("group"));
ExpressRunner runner = new ExpressRunner();
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.addOperator("join",new JoinOperator());
Object r = runner.execute("group(1,2,3)", context, null, false, false);
System.out.println(r);
//返回结果  6

```

* 类的静态方法，对象的方法绑定：addFunctionOfClassMethod+addFunctionOfServiceMethod

```

public class BeanExample {
	public static String upper(String abc) {
		return abc.toUpperCase();
	}
	public boolean anyContains(String str, String searchStr) {

        char[] s = str.toCharArray();
        for (char c : s) {
            if (searchStr.contains(c+"")) {
                return true;
            }
        }
        return false;
    }
}

runner.addFunctionOfClassMethod("取绝对值", Math.class.getName(), "abs",
				new String[] { "double" }, null);
runner.addFunctionOfClassMethod("转换为大写", BeanExample.class.getName(),
				"upper", new String[] { "String" }, null);

runner.addFunctionOfServiceMethod("打印", System.out, "println",new String[] { "String" }, null);
runner.addFunctionOfServiceMethod("contains", new BeanExample(), "anyContains",
            new Class[] { String.class, String.class }, null);

String exp = “取绝对值(-100);转换为大写(\"hello world\");打印(\"你好吗？\")；contains("helloworld",\"aeiou\")”;
runner.execute(exp, context, null, false, false);

```
* macro 宏定义

```
runner.addMacro("计算平均成绩", "(语文+数学+英语)/3.0");
runner.addMacro("是否优秀", "计算平均成绩>90");
IExpressContext<String, Object> context =new DefaultContext<String, Object>();
context.put("语文", 88);
context.put("数学", 99);
context.put("英语", 95);
Object result = runner.execute("是否优秀", context, null, false, false);
System.out.println(r);
//返回结果true

```

* 编译脚本，查询外部需要定义的变量，注意以下脚本int和没有int的区别

```
String express = "int 平均分 = (语文+数学+英语+综合考试.科目2)/4.0;return 平均分";
ExpressRunner runner = new ExpressRunner(true,true);
String[] names = runner.getOutVarNames(express);
for(String s:names){
 System.out.println("var : " + s);
}

//输出结果：

var : 数学
var : 综合考试
var : 英语
var : 语文
```

* 关于不定参数的使用

```
    @Test
    public void testMethodReplace() throws Exception {
        ExpressRunner runner = new ExpressRunner();
        IExpressContext<String,Object> expressContext = new DefaultContext<String,Object>();
        runner.addFunctionOfServiceMethod("getTemplate", this, "getTemplate", new Class[]{Object[].class}, null);

        //(1)默认的不定参数可以使用数组来代替
        Object r = runner.execute("getTemplate([11,'22',33L,true])", expressContext, null,false, false);
        System.out.println(r);
        //(2)像java一样,支持函数动态参数调用,需要打开以下全局开关,否则以下调用会失败
        DynamicParamsUtil.supportDynamicParams = true;
        r = runner.execute("getTemplate(11,'22',33L,true)", expressContext, null,false, false);
        System.out.println(r);
    }
    //等价于getTemplate(Object[] params)
    public Object getTemplate(Object... params) throws Exception{
        String result = "";
        for(Object obj:params){
            result = result+obj+",";
        }
        return result;
    }
 ```
* 关于集合的快捷写法

```
    @Test
    public void testSet() throws Exception {
        ExpressRunner runner = new ExpressRunner(false,false);
        DefaultContext<String, Object> context = new DefaultContext<String, Object>();
        String express = "abc = NewMap(1:1,2:2); return abc.get(1) + abc.get(2);";
        Object r = runner.execute(express, context, null, false, false);
        System.out.println(r);
        express = "abc = NewList(1,2,3); return abc.get(1)+abc.get(2)";
        r = runner.execute(express, context, null, false, false);
        System.out.println(r);
        express = "abc = [1,2,3]; return abc[1]+abc[2];";
        r = runner.execute(express, context, null, false, false);
        System.out.println(r);
    }

```
### 2.2 与Spring 结合
* 方案1：手工注入bean
```
public void test(){
    ExpressRunner runner = new ExpressRunner();
    DefaultContext<String, Object> context = new DefaultContext<String, Object>();
    Context.put(“orderId”,100012L);
    Context.put(“bizOrderDao”,getSpringBean("bizOrderDao"));
    Context.put(“tradeHsfBean”,getSpringBean("tradeHsfBean"));
    Context.put(“refundHsfBean”,getSpringBean("refundHsfBean"));

    Object result = runner.execute(text, context, null,true, false);
    system.out.println(result);
}
```
* 方案2：扩展上下文，自动注入bean
解决方案：把DefaultContext升级为SpringBeanContext
```
public class SpringBeanContext extends HashMap<String,Object>
implements IExpressContext<String,Object> {
    private ApplicationContext applicationContext;
    Public SpringBeanContext(Map<String,Object> aProperties,ApplicationContext applicationContext)
    {
        super(aProperties);
        this.applicationContext = applicationContext;
    }
    /**
    * 根据key从容器里面获取对象
    *
    * @param key
    * @return
    */
    public Object get(Object key) {
        Object object = super.get(key);
        try {
            if (object == null && this.applicationContext != null
                && this.applicationContext.containsBean((String)key))
            {
                object = this.applicationContext.getBean((String)key);
            }
        } catch (Exception e) {
            throw new RuntimeException("表达式容器获取对象失败", e);
        }
        return object;
    }
    /**
    * 把key-value放到容器里面去
    *
    * @param key
    * @param value
    */
    public Object put(String key, Object value) {
        return super.put(key, value);
    }
}

@Service
public SpringBeanRunner implements ApplicationContextAware
{
    private ApplicationContext applicationContext;
    private ExpressRunner runner;

    @override
    public void setApplicationContext(ApplicationContext context) {
        this.applicationContext = context;
        runner = new ExpressRunner();
    }
    public Object executeExpress(String text,Map<String,Object> context)
    {
        IExpressContext<String,Object> expressContext = new SpringBeanContext(context,this.applicationContext);
        try{
            return runner.execute(text, expressContext, null, true, false);
        }catch(Exception e){
            logger.error("qlExpress运行出错！",e);
        }
        return null;

    }
}
```
至此，通过对runner的简单封装，你现在只要直接使用这样的代码就可以轻松完成你对bean的调用了。
```
@Resource
private SpringBeanRunner runner;

public void test(){
    Map<String, Object> context = new HashMap<String, Object>();
    Context.put("orderId",100012L);
    Object result = runner.executeExpress(text, context);
    system.out.println(result);
}
```
### 2.3 替换现有操作符实现逻辑
  由于实际需求比较复杂，内置的操作符的实现逻辑可能并不能满足要求，但是又不能简单的新增一个自定义的操作符，只能替换掉现有操作符的实现逻辑，通过查看源码发现已经提供了这样的功能，在`com.ql.util.express.instruction.op.OperatorFactory` 里面有一个replaceOperator(String name, OperatorBase op)，这样就可以写一个自定义的Operator实现需求的中的功能。
## 3. 注意事项
* 字符串作为值输入时需要加上""
```
ExpressRunner runner = new ExpressRunner();
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
 context.put("d","abc");
Object r = runner.execute("abc == d", context, null, false, false); == false
r = runner.execute("\"abc\" == d", context, null, false, false); == true
```
* 字符串与数字有可能是相等的
```
 String expression = "175671177 == \"175671177\"";
 Assert.assertTrue(((Boolean) ExpressionUtils.execute(expression)) == true);
```
这是由于QLExpress在compareData的时候,会按照字符串 数字 和布尔的顺序进行比较，如果传入的两个值有一个为字符串，就会把另外一个也转成字符串再进行比较。
```
if(op1 instanceof String){
            compareResult = ((String)op1).compareTo(op2.toString());
        }else if(op2 instanceof String){
            compareResult = op1.toString().compareTo((String)op2);
        }else if(op1 instanceof Number && op2 instanceof Number){
            //数字比较
            compareResult =  OperatorOfNumber.compareNumber((Number)op1, (Number)op2);
        }else if ((op1 instanceof Boolean) && (op2 instanceof Boolean)) {
            if (((Boolean)op1).booleanValue() ==((Boolean)op2).booleanValue())
                compareResult =0;
            else
                compareResult =-1;
        }
        else
            throw new Exception(op1 + "和" + op2 +"不能执行compare 操作");
        return compareResult;
```

## 4. 参考
https://github.com/alibaba/qlExpress
http://blog.csdn.net/express_wind/article/details/78351561
http://blog.csdn.net/express_wind/article/details/78327650