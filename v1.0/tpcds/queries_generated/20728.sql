
WITH 
    customer_sales AS (
        SELECT 
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales_profit,
            COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales_profit,
            COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
        FROM 
            customer c
        LEFT JOIN 
            web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN 
            store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
        GROUP BY 
            c.c_customer_sk, c.c_first_name, c.c_last_name
    ),
    sales_performance AS (
        SELECT 
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            cs.total_web_sales_profit,
            cs.total_store_sales_profit,
            cs.web_order_count,
            cs.store_order_count,
            CASE 
                WHEN cs.total_web_sales_profit > cs.total_store_sales_profit THEN 'Web Dominant'
                WHEN cs.total_web_sales_profit < cs.total_store_sales_profit THEN 'Store Dominant'
                ELSE 'Equal Performance'
            END AS performance_category,
            ROW_NUMBER() OVER (PARTITION BY cs.performance_category ORDER BY (cs.total_web_sales_profit + cs.total_store_sales_profit) DESC) AS category_rank
        FROM 
            customer_sales cs
        JOIN 
            customer c ON cs.c_customer_sk = c.c_customer_sk
        WHERE 
            c.c_birth_year < 1980
    ),
    demographic_info AS (
        SELECT 
            cd.cd_gender,
            cd.cd_marital_status,
            COUNT(DISTINCT c.c_customer_sk) AS customer_count,
            MAX(cs.total_web_sales_profit) AS max_web_profit
        FROM 
            customer c
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN 
            customer_sales cs ON cs.c_customer_sk = c.c_customer_sk
        WHERE 
            cd.cd_purchase_estimate BETWEEN 100 AND 1000
        GROUP BY 
            cd.cd_gender, cd.cd_marital_status
    )
SELECT 
    s.performance_category,
    s.web_order_count,
    s.store_order_count,
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.max_web_profit,
    CASE 
        WHEN d.customer_count IS NULL THEN 'No Customers'
        ELSE 'Customers Present'
    END AS customer_presence,
    STRING_AGG(CONCAT(s.c_first_name, ' ', s.c_last_name), ', ') AS customer_names
FROM 
    sales_performance s
LEFT JOIN 
    demographic_info d ON s.performance_category = CASE 
        WHEN d.customer_count = 0 THEN 'Equal Performance'
        WHEN s.total_web_sales_profit > s.total_store_sales_profit THEN 'Web Dominant'
        ELSE 'Store Dominant'
    END
GROUP BY 
    s.performance_category, d.cd_gender, d.cd_marital_status, d.customer_count, d.max_web_profit
ORDER BY 
    s.performance_category, d.customer_count DESC;
