import boto3
import sys

# =============================================================================
# CONFIGURATION
# =============================================================================
# LocalStack endpoint - a local AWS simulator for development/testing
# This avoids costs and allows safe experimentation without affecting real AWS
AWS_REGION = "us-east-2"
ENDPOINT_URL = "http://localhost:4566"

# CIDR notation: /32 means a single IP address (full 32-bit mask)
MALICIOUS_IP = "203.0.113.5/32"

# =============================================================================
# SETUP CONNECTION
# =============================================================================
print(f"🔄 Connecting to LocalStack in {AWS_REGION}...")

# boto3.client creates a low-level service client for EC2
# EC2 client handles VPC, subnets, security groups, NACLs, and instances
ec2 = boto3.client(
    'ec2',
    region_name=AWS_REGION,
    endpoint_url=ENDPOINT_URL,
    # LocalStack accepts any credentials - "test" is conventional
    aws_access_key_id="test",
    aws_secret_access_key="test"
)

def find_vpc_id():
    """
    Retrieves the first VPC ID from the AWS account.
    
    A VPC (Virtual Private Cloud) is an isolated network environment.
    All network resources (subnets, NACLs, instances) belong to a VPC.
    """
    try:
        response = ec2.describe_vpcs()
        
        if response['Vpcs']:
            vpc_id = response['Vpcs'][0]['VpcId']
            print(f"✅ Found Target VPC: {vpc_id}")
            return vpc_id
        else:
            print("❌ No VPC found! Did you run 'terraform apply' in Week 8?")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Error finding VPC: {e}")
        sys.exit(1)

def find_nacl_id(vpc_id):
    """
    Finds the Network ACL associated with a VPC.
    
    NACL = Network Access Control List
    - Operates at the subnet level (stateless firewall)
    - Rules are evaluated in order by rule number (lowest first)
    - Unlike Security Groups, NACLs require explicit allow/deny for both directions
    """
    try:
        # Filter NACLs to only those belonging to our target VPC
        response = ec2.describe_network_acls(
            Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
        )
        
        if response['NetworkAcls']:
            nacl_id = response['NetworkAcls'][0]['NetworkAclId']
            print(f"✅ Found Network ACL: {nacl_id}")
            return nacl_id
        else:
            print("❌ No Network ACL found for this VPC.")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Error finding NACL: {e}")
        sys.exit(1)

def block_ip(nacl_id, ip_address):
    """
    Creates a DENY rule in the NACL to block all traffic from a specific IP.
    
    This is an automated remediation action - typically triggered by:
    - Intrusion detection systems (IDS)
    - Security incident alerts
    - Threat intelligence feeds
    """
    print(f"🛡️  Attempting to BLOCK malicious IP: {ip_address}...")
    
    try:
        response = ec2.create_network_acl_entry(
            NetworkAclId=nacl_id,
            # RuleNumber=1: Lowest number = highest priority
            # NACL rules are evaluated in ascending order; first match wins
            RuleNumber=1,
            # Protocol '-1' = all protocols (TCP, UDP, ICMP, etc.)
            # Use '6' for TCP-only or '17' for UDP-only
            Protocol='-1',
            RuleAction='deny',
            # Egress=False means INBOUND (ingress) traffic
            # Egress=True would block OUTBOUND traffic from our network
            Egress=False,
            CidrBlock=ip_address,
            # Port range 0-65535 covers all possible ports
            # Only applicable when Protocol is TCP (6) or UDP (17)
            PortRange={'From': 0, 'To': 65535}
        )
        print("✅ SUCCESS! IP Address blocked.")
        print(f"🚫 Rule created: DENY ALL from {ip_address} (Priority 1)")
        
    except Exception as e:
        print(f"❌ Failed to block IP: {e}")

# =============================================================================
# MAIN EXECUTION FLOW
# =============================================================================
# __name__ == "__main__" ensures this only runs when executed directly,
# not when imported as a module by another script
if __name__ == "__main__":
    # Step 1: Discover existing infrastructure
    my_vpc = find_vpc_id()
    my_nacl = find_nacl_id(my_vpc)
    
    # Step 2: Apply security remediation by blocking the malicious IP
    block_ip(my_nacl, MALICIOUS_IP)