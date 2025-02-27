
WITH customer_stats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
address_data AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_state
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_customers,
    cs.avg_purchase_estimate,
    sd.total_sales,
    sd.total_quantity,
    ad.address_count
FROM 
    customer_stats cs
LEFT JOIN 
    sales_data sd ON cs.total_customers = (SELECT COUNT(*) FROM customer WHERE c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = cs.cd_gender AND cd_marital_status = cs.cd_marital_status))
LEFT JOIN 
    address_data ad ON ad.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = cs.cd_gender AND cd_marital_status = cs.cd_marital_status) LIMIT 1)
WHERE 
    ad.address_count > 0
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
