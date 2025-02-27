
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
    WHERE ws_sales_price > 0
),
average_profit AS (
    SELECT 
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales
    JOIN customer ON ws_ship_customer_sk = c_customer_sk
    GROUP BY c_customer_sk
    HAVING SUM(ws_net_paid) > (
        SELECT COALESCE(AVG(total_spent), 0) FROM (
            SELECT SUM(ws_net_paid) AS total_spent
            FROM web_sales
            GROUP BY ws_bill_customer_sk
        ) AS customer_spending
    )
),
item_summary AS (
    SELECT 
        i_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    JOIN item ON ws_item_sk = i_item_sk
    GROUP BY i_item_sk
),
item_ranked_profit AS (
    SELECT 
        i_item_sk,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC NULLS LAST) AS item_rank
    FROM item_summary
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    irp.i_item_sk,
    irp.total_profit,
    irp.item_rank,
    COALESCE(hvc.total_spent, 0) AS customer_spending,
    CASE 
        WHEN irp.item_rank = 1 THEN 'Top Item'
        WHEN irp.total_profit >= (SELECT avg_profit FROM average_profit) THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_category
FROM customer AS c
LEFT JOIN ranked_sales AS rs ON c.c_customer_sk = rs.ws_bill_customer_sk
JOIN item_ranked_profit AS irp ON rs.ws_item_sk = irp.i_item_sk AND rs.rank <= 5
LEFT JOIN high_value_customers AS hvc ON c.c_customer_sk = hvc.c_customer_sk
WHERE c.c_current_cdemo_sk IS NOT NULL
ORDER BY irp.total_profit DESC, customer_spending DESC;
