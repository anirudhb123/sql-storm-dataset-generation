
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS level,
        CAST(c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1,
        CAST(ch.full_name || ' -> ' || c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100))
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
sales_summary AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_order_number
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.total_sales) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ss.total_sales) > 1000
)
SELECT 
    ch.level,
    ch.full_name,
    hvc.customer_total_sales,
    COALESCE(SUM(ws.ws_net_paid), 0) AS web_total_sales,
    COALESCE(SUM(cs.cs_net_paid), 0) AS catalog_total_sales,
    COALESCE(SUM(ss.ss_net_paid), 0) AS store_total_sales
FROM 
    customer_hierarchy ch
LEFT JOIN 
    high_value_customers hvc ON ch.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = ch.c_customer_sk
LEFT JOIN 
    catalog_sales cs ON cs.cs_bill_customer_sk = ch.c_customer_sk
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk = ch.c_customer_sk
GROUP BY 
    ch.level, ch.full_name, hvc.customer_total_sales
ORDER BY 
    ch.level, hvc.customer_total_sales DESC;
