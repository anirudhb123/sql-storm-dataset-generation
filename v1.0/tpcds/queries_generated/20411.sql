
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d
            WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_current_year = 'Y')
            AND d.d_weekend = 'Y'
        )
),
top_sales AS (
    SELECT 
        ws_order_number, 
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM sales_data
    WHERE rn <= 5
    GROUP BY ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ci.total_sales_price,
        ci.total_net_profit
    FROM 
        customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN top_sales ci ON ci.ws_order_number = (SELECT ws_order_number 
                                                FROM web_sales 
                                                WHERE ws_bill_customer_sk = c.c_customer_sk 
                                                LIMIT 1)
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    COALESCE(ci.total_sales_price, 0) AS total_sales_price,
    COALESCE(ci.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN ci.cd_marital_status = 'M' AND ci.cd_purchase_estimate > 1000 THEN 'High Value Married'
        WHEN ci.cd_marital_status = 'S' AND ci.cd_purchase_estimate <= 1000 THEN 'Single Saver'
        ELSE 'Other'
    END AS customer_category
FROM 
    customer_info ci
WHERE 
    EXISTS (
        SELECT 1 
        FROM store s 
        WHERE ci.total_sales_price > ALL (
            SELECT total_sales_price 
            FROM top_sales 
            WHERE total_net_profit IS NOT NULL
        )
    ) OR 
    NOT EXISTS (
        SELECT 1 
        FROM inventory i 
        WHERE i.inv_quantity_on_hand = 0 AND i.inv_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_id LIMIT 1)
    )
ORDER BY 
    ci.total_net_profit DESC
LIMIT 10 OFFSET 5;
