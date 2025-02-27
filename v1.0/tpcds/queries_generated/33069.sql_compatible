
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        c_current_addr_sk,
        1 AS level
    FROM 
        customer 
    WHERE 
        c_current_hdemo_sk IS NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_current_addr_sk,
        ch.level + 1
    FROM 
        customer c 
    JOIN 
        customer_hierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
total_returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
sales_adjusted AS (
    SELECT 
        ts.ws_bill_customer_sk,
        ts.total_profit - COALESCE(tr.total_return_loss, 0) AS adjusted_profit
    FROM 
        total_sales ts 
    LEFT JOIN 
        total_returns tr ON ts.ws_bill_customer_sk = tr.wr_returning_customer_sk
),
final_results AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_preferred_cust_flag,
        sa.adjusted_profit,
        ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY sa.adjusted_profit DESC) AS rank
    FROM 
        customer_hierarchy ch 
    JOIN 
        sales_adjusted sa ON ch.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT 
    f.c_customer_sk, 
    f.c_first_name, 
    f.c_last_name, 
    f.c_preferred_cust_flag, 
    f.adjusted_profit 
FROM 
    final_results f 
WHERE 
    f.rank <= 10 
ORDER BY 
    f.adjusted_profit DESC;
