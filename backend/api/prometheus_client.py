import requests
from datetime import datetime

class PrometheusClient:
    def __init__(self, url='http://10.10.1.7:9090'):
        self.url = url
    
    def query(self, query):
        """Execute PromQL query"""
        try:
            response = requests.get(
                f'{self.url}/api/v1/query',
                params={'query': query},
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            print(f"Prometheus query error: {e}")
            return {'data': {'result': []}}
    
    def get_interface_bandwidth(self, instance, interface):
        """Get current bandwidth for an interface in Mbps"""
        query_in = f'sum(rate(ifHCInOctets{{instance="{instance}", ifName="{interface}"}}[5m]) * 8) / 1000000'
        query_out = f'sum(rate(ifHCOutOctets{{instance="{instance}", ifName="{interface}"}}[5m]) * 8) / 1000000'
        
        inbound = self.query(query_in)
        outbound = self.query(query_out)
        
        return {
            'inbound': round(self._extract_value(inbound), 2),
            'outbound': round(self._extract_value(outbound), 2),
            'timestamp': datetime.now().isoformat()
        }
    
    def _extract_value(self, result):
        """Extract numeric value from Prometheus result"""
        try:
            return float(result['data']['result'][0]['value'][1])
        except (KeyError, IndexError, ValueError):
            return 0.0
