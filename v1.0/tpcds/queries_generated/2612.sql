
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_country,
    cd.cd_gender,
    SUM(cp.total_spent) AS total_spent,
    AVG(cp.total_quantity) AS avg_quantity_per_customer,
    COUNT(DISTINCT cp.c_customer_sk) AS unique_customers,
    MAX(rs.ws_sales_price) AS max_single_order_price
FROM 
    customer_address ca
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk)
LEFT JOIN 
    CustomerPurchases cp ON cp.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk)
LEFT JOIN 
    RankedSales rs ON rs.ws_order_number = cp.total_orders
WHERE 
    ca.ca_state = 'CA' AND 
    (cd.cd_marital_status = 'S' OR cd.cd_gender = 'F') AND 
    (cp.total_spent IS NOT NULL AND cp.total_spent > 1000)
GROUP BY 
    ca.ca_country, cd.cd_gender
HAVING 
    COUNT(DISTINCT cp.c_customer_sk) > 10
ORDER BY 
    total_spent DESC;
