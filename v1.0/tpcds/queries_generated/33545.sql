
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.store_sk, 
        s.store_name, 
        s.store_id, 
        1 AS level
    FROM 
        store s
    WHERE 
        s.store_sk IS NOT NULL

    UNION ALL 

    SELECT 
        s.store_sk, 
        s.store_name, 
        s.store_id, 
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.store_sk = sh.store_sk + 1
    WHERE 
        sh.level < 10
),
daily_sales AS (
    SELECT 
        d.d_date, 
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
customer_data AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'S' AND 
        cd.cd_gender = 'M' 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
store_performance AS (
    SELECT 
        s.s_store_name,
        SUM(sr.sr_return_quantity) AS total_returns,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM 
        store s 
    LEFT JOIN 
        store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY 
        s.s_store_name
)
SELECT 
    sh.store_name,
    ds.d_date,
    COALESCE(ds.total_sales, 0) AS sales,
    COALESCE(cd.total_orders, 0) AS orders,
    COALESCE(sp.total_returns, 0) AS returns,
    COALESCE(sp.avg_return_amt, 0.00) AS avg_return,
    ROW_NUMBER() OVER (PARTITION BY sh.store_name ORDER BY ds.d_date DESC) AS sales_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    daily_sales ds ON ds.d_date = CURRENT_DATE
LEFT JOIN 
    customer_data cd ON cd.c_customer_sk = sh.store_sk
LEFT JOIN 
    store_performance sp ON sp.s_store_name = sh.store_name
WHERE 
    (ds.total_sales IS NOT NULL OR cd.total_orders IS NOT NULL OR sp.total_returns IS NOT NULL)
ORDER BY 
    sh.store_name, ds.d_date;
