import urllib3

def handler(event, context):
    http = urllib3.PoolManager()
    response = http.request('GET', 'https://checkip.amazonaws.com/')
    ip = response.data.decode('utf-8').strip()
    
    return {
        'statusCode': 200,
        'body': {
            'message': 'Success',
            'ip': ip
        }
    }
