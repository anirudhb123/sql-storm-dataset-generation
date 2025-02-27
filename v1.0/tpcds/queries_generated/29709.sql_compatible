
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_street_name) AS processed_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', 
               ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.ed_status,
        cd.cd_gender,
        ca.processed_street_name,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        ProcessedAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
MarketingStats AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages_visited
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.cd_gender
)
SELECT 
    cd_gender,
    AVG(total_orders) AS avg_orders,
    AVG(total_spent) AS avg_spent,
    COUNT(DISTINCT full_name) AS customer_count
FROM 
    MarketingStats
GROUP BY 
    cd_gender
ORDER BY 
    avg_spent DESC;
