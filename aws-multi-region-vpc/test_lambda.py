from lambda_function import handler

def main():
    # 模拟AWS Lambda的event和context参数
    event = {}
    context = None
    
    # 调用Lambda函数
    try:
        result = handler(event, context)
        print("Lambda函数执行成功!")
        print("返回结果:", result)
    except Exception as e:
        print("Lambda函数执行失败!")
        print("错误信息:", str(e))

if __name__ == "__main__":
    main()
