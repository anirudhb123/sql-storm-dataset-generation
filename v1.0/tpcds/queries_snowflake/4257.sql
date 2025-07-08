
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sales_price IS NOT NULL
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
),
high_value_customers AS (
    SELECT
        c.c_customer_sk,
        cs.total_quantity,
        cs.avg_sales_price,
        CASE 
            WHEN cs.order_count > 10 THEN 'Gold'
            WHEN cs.order_count BETWEEN 5 AND 10 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM
        customer_stats cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.total_quantity > 100
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hvc.customer_tier, 'None') AS customer_tier,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
    COALESCE(ARRAY_AGG(DISTINCT i.i_product_name ORDER BY i.i_product_name), 'No Products') AS featured_products
FROM 
    customer c
LEFT JOIN 
    high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, hvc.customer_tier
ORDER BY 
    total_profit DESC
LIMIT 100;
