
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ss_store_sk
    HAVING 
        SUM(ss_sales_price) > 1000
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        cd_gender,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk, cd_marital_status, cd_gender
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(SUM(ws.net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        store s
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    s.s_store_name,
    ss.total_sales,
    ss.total_transactions,
    cs.marital_status,
    cs.cd_gender,
    cs.order_count,
    cs.total_spent,
    si.total_profit
FROM 
    sales_cte ss
INNER JOIN 
    store_info si ON ss.ss_store_sk = si.s_store_sk
LEFT JOIN 
    customer_stats cs ON ss.ss_store_sk = cs.c_customer_sk
WHERE 
    si.total_profit > (SELECT AVG(total_profit) FROM store_info)
ORDER BY 
    ss.total_sales DESC, cs.total_spent DESC
LIMIT 10;
