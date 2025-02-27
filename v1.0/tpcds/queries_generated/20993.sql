
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
return_stats AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_returns, 0) / NULLIF(cs.total_orders, 0) AS return_rate
    FROM 
        customer_summary cs
    LEFT JOIN return_stats rs ON cs.c_customer_sk = rs.sr_customer_sk
)

SELECT 
    fs.c_customer_sk,
    fs.total_orders,
    fs.total_profit,
    fs.total_returns,
    fs.total_return_amount,
    fs.return_rate,
    (SELECT COUNT(DISTINCT p.p_promo_id) 
     FROM promotion p 
     WHERE p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d) 
       AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d)
     ) AS active_promotions
FROM 
    final_summary fs
WHERE 
    fs.total_profit > 1000
ORDER BY 
    fs.return_rate DESC NULLS LAST
LIMIT 10;
