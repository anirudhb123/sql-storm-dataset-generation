
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) as total_quantity,
        SUM(ws_net_profit) as total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_ranking AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        RANK() OVER (PARTITION BY cd_gender ORDER BY COUNT(ws_order_number) DESC) AS rank_by_gender
    FROM customer 
    JOIN web_sales ON c_customer_sk = ws_bill_customer_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd_gender
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    COALESCE(ss.total_quantity, 0) as total_sales_quantity,
    COALESCE(ss.total_profit, 0) as total_sales_profit,
    CASE 
        WHEN cr.return_count > 0 THEN 'Returned' 
        ELSE 'Not Returned' 
    END as return_status,
    CASE 
        WHEN cr.return_count IS NOT NULL THEN cr.return_count
        ELSE 0
    END as return_count
FROM customer c
LEFT JOIN customer_ranking cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) as total_quantity,
        SUM(ws_net_profit) as total_profit 
    FROM sales_summary
    WHERE rn = 1
    GROUP BY ws_item_sk
) ss ON c.c_current_hdemo_sk = ss.ws_item_sk
LEFT JOIN (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) as return_count
    FROM store_returns
    GROUP BY sr_customer_sk
) cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
AND 
    (cd_gender = 'F' OR cd_gender IS NULL)
ORDER BY 
    total_sales_profit DESC, c.c_last_name ASC;
