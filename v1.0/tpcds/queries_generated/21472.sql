
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_status AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_details AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_net_profit,
        COALESCE(ws.ws_net_paid, 0) AS net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    MAX(sd.ws_net_profit) AS max_profit,
    MIN(sd.net_paid) AS min_paid,
    SUM(sd.net_paid) AS total_paid,
    STRING_AGG(CONCAT(cs.c_preferred_cust_flag, ': ', cs.purchase_category) ORDER BY cs.purchase_category) AS customer_summary
FROM 
    ranked_sales s
JOIN 
    sales_details sd ON s.ws_item_sk = sd.ws_item_sk
LEFT JOIN 
    customer_status cs ON cs.c_customer_sk IN (
        SELECT 
            DISTINCT ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = s.ws_item_sk
    )
WHERE 
    s.sales_rank = 1
    AND sd.profit_rank <= 10
GROUP BY 
    s.ws_item_sk, s.total_sales
HAVING 
    COUNT(DISTINCT cs.c_customer_sk) > 0
ORDER BY 
    s.total_sales DESC, max_profit DESC
FETCH FIRST 100 ROWS ONLY;
