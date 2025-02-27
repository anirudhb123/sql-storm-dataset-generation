
WITH customer_returns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_reason_sk,
        wr_return_quantity,
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    GROUP BY 
        wr_returning_customer_sk,
        wr_reason_sk,
        wr_returned_date_sk
),
sales_summary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
return_reasons AS (
    SELECT 
        r_reason_sk, 
        r_reason_desc
    FROM reason
),
warehouse_info AS (
    SELECT
        w_warehouse_sk,
        COUNT(DISTINCT ws_order_number) AS orders_from_warehouse,
        MAX(ws_net_paid) AS highest_order_amount
    FROM web_sales
    JOIN warehouse ON ws_warehouse_sk = w_warehouse_sk
    GROUP BY w_warehouse_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    SUM(cr.return_quantity) AS total_returned,
    s.total_net_profit,
    s.order_count,
    r.r_reason_desc,
    w.orders_from_warehouse,
    w.highest_order_amount,
    CASE 
        WHEN s.order_count > 10 THEN 'Frequent'
        WHEN s.order_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Rare'
    END AS purchase_frequency,
    COALESCE(cr.total_return_amount, 0) AS return_amount,
    CASE 
        WHEN cr.wr_returned_date_sk IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN sales_summary s ON c.c_customer_sk = s.ws_ship_customer_sk
LEFT JOIN return_reasons r ON cr.w_reason_sk = r.r_reason_sk
LEFT JOIN warehouse_info w ON w.w_warehouse_sk IN (
    SELECT w_warehouse_sk
    FROM web_sales
    WHERE ws_ship_customer_sk = c.c_customer_sk
)
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
    AND (s.order_count IS NULL OR s.order_count > 2)
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    r.r_reason_desc,
    w.orders_from_warehouse,
    w.highest_order_amount,
    cr.wr_returned_date_sk
ORDER BY 
    total_returned DESC, 
    total_net_profit DESC;
