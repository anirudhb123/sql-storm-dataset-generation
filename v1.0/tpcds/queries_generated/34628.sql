
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
profit_threshold AS (
    SELECT 
        AVG(total_profit) AS avg_profit
    FROM 
        sales_summary
),
sales_comparison AS (
    SELECT 
        customer.c_first_name,
        customer.c_last_name,
        ss.total_profit,
        pt.avg_profit,
        (ss.total_profit - pt.avg_profit) AS profit_difference
    FROM 
        sales_summary ss
    CROSS JOIN 
        profit_threshold pt
    WHERE 
        ss.rank_order <= 10 
        AND ss.total_profit > pt.avg_profit
)
SELECT 
    sc.c_first_name,
    sc.c_last_name,
    sc.total_profit,
    sc.profit_difference,
    COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
    COALESCE(sr.sr_return_amt, 0) AS return_amount
FROM 
    sales_comparison sc
LEFT JOIN 
    store_returns sr ON sc.c_customer_sk = sr.sr_customer_sk
WHERE 
    sc.profit_difference > 0
ORDER BY 
    sc.total_profit DESC;
