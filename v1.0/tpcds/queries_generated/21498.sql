
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    ca.ca_state,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    SUM(cs.total_orders) AS total_orders,
    AVG(cs.avg_spent) AS avg_spent,
    MAX(case when cs.total_spent IS NULL THEN 0 ELSE cs.total_spent END) AS max_spent,
    SUM(CASE WHEN r.r_reason_sk IS NOT NULL THEN 1 ELSE 0 END) AS return_count,
    COUNT(DISTINCT CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_order_number END) AS high_value_orders
FROM 
    customer_address ca
LEFT JOIN 
    customer_stats cs ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = cs.c_customer_sk
LEFT JOIN 
    reason r ON r.r_reason_sk = sr.sr_reason_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = cs.c_customer_sk
WHERE 
    (ca.ca_state IS NOT NULL OR ca.ca_country = 'USA')
    AND (ca.ca_gmt_offset IS NOT NULL OR cs.total_orders > 0)
    AND (sr.sr_returned_date_sk IS NULL OR sr.sr_return_quantity > 0)
GROUP BY 
    ca.ca_state, cd.cd_gender
HAVING 
    COUNT(DISTINCT cs.total_orders) > 1
ORDER BY 
    ca.ca_state, gender DESC
FETCH FIRST 100 ROWS ONLY;
