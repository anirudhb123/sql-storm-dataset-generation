
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_purchased,
        AVG(COALESCE(ws.ws_net_profit, 0)) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city
),
discounted_sales AS (
    SELECT 
        cs.cs_item_sk,
        CASE 
            WHEN cs.cs_ext_discount_amt IS NULL THEN 'No Discount'
            ELSE 'Discounted'
        END AS discount_status,
        SUM(cs.cs_ext_sales_price) AS total_discounted_sales
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk, discount_status
)
SELECT 
    c.c_customer_id,
    cp.total_purchased,
    cp.avg_net_profit,
    COALESCE(ds.total_discounted_sales, 0) AS total_discounted_sales,
    CASE 
        WHEN cp.total_purchased > 100 THEN 'High Purchaser'
        WHEN cp.avg_net_profit < 0 THEN 'Negative Profit'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT 
        COUNT(DISTINCT cc.cc_call_center_sk) FROM call_center cc 
        WHERE cc.cc_market_desc LIKE '%suburb%' AND cc.cc_employees > 50
    ) AS total_suburban_centers
FROM 
    customer_purchases cp 
JOIN 
    customer c ON cp.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    discounted_sales ds ON ds.cs_item_sk = (SELECT 
        i.i_item_sk 
        FROM item i 
        WHERE i.i_item_id IN (SELECT DISTINCT ws.ws_web_page_sk FROM web_sales ws) 
        ORDER BY RAND() 
        LIMIT 1) 
WHERE 
    cp.avg_net_profit IS NOT NULL
ORDER BY 
    cp.total_purchased DESC, cp.avg_net_profit DESC
LIMIT 50;
