
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographic_summary AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_web_profit) AS web_profit,
        SUM(cs.total_store_profit) AS store_profit
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics d ON cs.c_customer_id = d.cd_demo_sk
    GROUP BY 
        d.cd_gender, d.cd_marital_status
),
date_summary AS (
    SELECT 
        dd.d_year,
        SUM(cs.total_web_profit) AS total_web_profit,
        SUM(cs.total_store_profit) AS total_store_profit
    FROM 
        customer_sales cs
    JOIN 
        web_sales ws ON cs.c_customer_id = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    ds.d_year,
    ds.total_web_profit,
    ds.total_store_profit,
    ds.total_web_profit + ds.total_store_profit AS total_profit,
    ds.total_web_profit / NULLIF(ds.total_web_profit + ds.total_store_profit, 0) * 100 AS web_profit_percentage,
    ds.total_store_profit / NULLIF(ds.total_web_profit + ds.total_store_profit, 0) * 100 AS store_profit_percentage,
    ds.total_web_profit / COUNT(DISTINCT cs.c_customer_id) AS average_web_profit_per_customer,
    ds.total_store_profit / COUNT(DISTINCT cs.c_customer_id) AS average_store_profit_per_customer
FROM 
    date_summary ds
JOIN 
    customer_sales cs ON ds.total_web_profit > 0 OR ds.total_store_profit > 0
GROUP BY 
    ds.d_year, ds.total_web_profit, ds.total_store_profit
ORDER BY 
    ds.d_year;
