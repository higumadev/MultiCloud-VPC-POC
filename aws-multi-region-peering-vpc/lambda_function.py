import urllib3
import json
import socket
import time
import os

def lambda_handler(event, context):
    print("Starting Lambda execution")
    print(f"Function name: {context.function_name}")
    
    # 1. 环境信息
    print("\n=== Environment Info ===")
    print(f"AWS_REGION: {os.environ.get('AWS_REGION')}")
    
    # 2. DNS 测试
    print("\n=== DNS Tests ===")
    test_domains = [
        'checkip.amazonaws.com',
        's3.amazonaws.com',
        'api.amazonwebservices.com'
    ]
    
    resolved_ips = {}
    for domain in test_domains:
        try:
            print(f"\nTesting DNS resolution for {domain}")
            start_time = time.time()
            ip = socket.gethostbyname(domain)
            duration = time.time() - start_time
            print(f" Resolved {domain} -> {ip} in {duration:.2f}s")
            resolved_ips[domain] = ip
        except Exception as e:
            print(f" Failed to resolve {domain}: {str(e)}")
    
    # 3. TCP 连接测试
    print("\n=== TCP Connection Tests ===")
    for domain, ip in resolved_ips.items():
        try:
            print(f"\nTesting TCP connection to {domain} ({ip}:443)")
            # 直接使用解析到的IP
            start_time = time.time()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)  # 增加超时时间到10秒
            
            # 尝试连接
            print(f"Attempting to connect to {ip}:443...")
            result = sock.connect_ex((ip, 443))
            duration = time.time() - start_time
            
            if result == 0:
                print(f" Connected to {domain} ({ip}:443) in {duration:.2f}s")
                # 尝试发送一个简单的HTTP请求
                try:
                    sock.send(b"GET / HTTP/1.0\r\nHost: " + domain.encode() + b"\r\n\r\n")
                    print(" Successfully sent HTTP request")
                    # 接收响应的第一个字节
                    sock.settimeout(5)
                    first_byte = sock.recv(1)
                    print(" Received response from server")
                except Exception as e:
                    print(f" Failed to communicate after connection: {str(e)}")
            else:
                print(f" Failed to connect to {domain} ({ip}:443): error {result}")
            
            sock.close()
        except Exception as e:
            print(f" Connection test failed for {domain}: {str(e)}")
    
    # 4. HTTP 请求测试
    print("\n=== HTTP Request Test ===")
    try:
        print("Creating HTTP client...")
        http = urllib3.PoolManager(
            timeout=urllib3.Timeout(
                connect=10.0,  # 增加连接超时到10秒
                read=10.0      # 增加读取超时到10秒
            ),
            retries=urllib3.Retry(
                total=2,        # 减少重试次数
                backoff_factor=1,
                status_forcelist=[500, 502, 503, 504]
            )
        )
        
        print("Starting HTTP request to checkip.amazonaws.com...")
        start_time = time.time()
        response = http.request('GET', 'https://checkip.amazonaws.com/')
        request_time = time.time() - start_time
        
        ip = response.data.decode('utf-8').strip()
        print(f" Request successful in {request_time:.2f}s")
        print(f" Retrieved IP: {ip}")
        
        return {
            'statusCode': 200,
            'body': {
                'source_ip': ip,
                'function_name': context.function_name,
                'request_time_seconds': request_time,
                'dns_results': resolved_ips
            }
        }
    except Exception as e:
        print(f" HTTP request failed: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        if hasattr(e, 'args'):
            print(f"Error args: {e.args}")
        raise
