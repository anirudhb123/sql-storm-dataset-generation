
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk >= 20210101
    GROUP BY 
        s_store_sk, ss_sold_date_sk
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.ss_sold_date_sk,
        SUM(sh.total_profit) + SUM(ss.net_profit) 
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND sh.ss_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        sh.s_store_sk, sh.ss_sold_date_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        s.ss_item_sk,
        CASE 
            WHEN s.ss_quantity > 10 THEN 'Bulk'
            ELSE 'Single'
        END AS sale_type,
        SUM(s.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, s.ss_item_sk, sale_type
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.ss_item_sk,
        cs.sale_type,
        cs.total_profit,
        RANK() OVER (PARTITION BY cs.sale_type ORDER BY cs.total_profit DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_profit > 100.00
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    COALESCE(SUM(r.total_profit), 0) AS total_sales_profit,
    CASE 
        WHEN COUNT(DISTINCT cs.c_customer_sk) > 0 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ranked_sales r ON c.c_customer_sk = r.c_customer_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales_profit DESC, customer_count DESC 
LIMIT 10;
