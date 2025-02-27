
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        1 AS tier
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ch.tier + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
combined_summary AS (
    SELECT 
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        COALESCE(rs.total_returns, 0) AS total_returns,
        CASE 
            WHEN ss.total_net_profit IS NULL THEN 'No Sales'
            WHEN rs.total_return_amt > ss.total_net_profit THEN 'High Returns'
            ELSE 'Good Standing'
        END AS customer_status
    FROM 
        customer_hierarchy ch
    LEFT JOIN 
        sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        returns_summary rs ON ch.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    CONVERT(CHAR(20), c.c_first_name + ' ' + c.c_last_name) AS full_name,
    cs.total_net_profit,
    cs.total_orders,
    cs.total_return_amt,
    cs.total_returns,
    cs.customer_status,
    ROW_NUMBER() OVER (PARTITION BY cs.customer_status ORDER BY cs.total_net_profit DESC) AS status_rank
FROM 
    combined_summary cs
JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
WHERE 
    cs.total_net_profit > 1000 -- Only customers with significant net profit
ORDER BY 
    cs.customer_status, 
    cs.total_net_profit DESC;
