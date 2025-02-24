import requests

def handler(event, context):
    # 目标公网地址
    public_url = "https://httpbin.org/ip"
    
    # 从事件中获取是否使用 VPC-B 的 NAT Gateway
    use_vpc_b = event.get('use_vpc_b', False)
    
    try:
        if use_vpc_b:
            # 通过 VPC-B 的 NAT Gateway 出口
            # 通过请求特定的私有 IP 地址触发路由 (假设 10.1.1.100 是一个 VPC-B 中的特殊跳板 IP)
            target_ip = "10.1.1.100"  # 这个 IP 在 VPC-A 的路由表中指向 Transit Gateway
            response = requests.get(public_url, proxies={"http": f"http://{target_ip}", "https": f"http://{target_ip}"})
        else:
            # 通过 VPC-A 的 NAT Gateway 直接访问公网
            response = requests.get(public_url)
        
        return {
            "statusCode": 200,
            "body": response.json()
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": str(e)
        }
