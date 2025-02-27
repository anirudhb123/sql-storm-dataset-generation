
WITH AddressInfo AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.customer_sk) AS total_customers,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
SalesInfo AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
CombinedInfo AS (
    SELECT 
        ai.city,
        ai.state,
        ai.total_customers,
        ai.female_customers,
        ai.male_customers,
        si.total_sales,
        si.total_orders
    FROM 
        AddressInfo ai
    LEFT JOIN 
        SalesInfo si ON ai.state = (SELECT w.state FROM warehouse w WHERE w.warehouse_sk = si.web_site_sk)
)
SELECT 
    city,
    state,
    total_customers,
    female_customers,
    male_customers,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    ROUND((COALESCE(total_sales, 0) / NULLIF(total_customers, 0)), 2) AS avg_sales_per_customer
FROM 
    CombinedInfo
ORDER BY 
    avg_sales_per_customer DESC
LIMIT 10;
