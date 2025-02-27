
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ticket_number) AS total_store_sales,
        COUNT(DISTINCT ws.order_number) AS total_web_sales,
        AVG(ss.net_profit) OVER (PARTITION BY c.c_customer_sk) AS avg_store_net_profit,
        AVG(ws.net_profit) OVER (PARTITION BY c.c_customer_sk) AS avg_web_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_store_sales, 0) AS total_store_sales,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        LEAST(cs.avg_store_net_profit, cs.avg_web_net_profit) AS min_avg_net_profit,
        GREATEST(cs.avg_store_net_profit, cs.avg_web_net_profit) AS max_avg_net_profit
    FROM 
        customer_stats cs
)

SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_store_sales,
    s.total_web_sales,
    CASE 
        WHEN s.total_store_sales + s.total_web_sales = 0 THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    CASE 
        WHEN s.min_avg_net_profit IS NULL THEN 'N/A' 
        ELSE CONCAT('$', ROUND(s.min_avg_net_profit, 2))
    END AS formatted_min_avg_net_profit,
    CASE 
        WHEN s.max_avg_net_profit IS NULL THEN 'N/A' 
        ELSE CONCAT('$', ROUND(s.max_avg_net_profit, 2))
    END AS formatted_max_avg_net_profit
FROM 
    sales_summary s
WHERE 
    (s.total_store_sales > 0 OR s.total_web_sales > 0)
ORDER BY 
    s.total_store_sales DESC, s.total_web_sales DESC
LIMIT 100;
