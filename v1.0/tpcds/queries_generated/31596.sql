
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        s.s_store_sk,
        sh.total_sales + COUNT(DISTINCT ss_ticket_number) AS total_sales,
        sh.total_profit + SUM(ss_net_profit) AS total_profit
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON s.s_store_sk = sh.ss_store_sk
    JOIN 
        store_sales ss ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        s.s_store_sk, sh.total_sales, sh.total_profit
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss_ticket_number) AS ticket_count,
        SUM(ss_net_profit) AS net_profit
    FROM 
        store_sales s
    JOIN 
        customer c ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.ticket_count,
        cs.net_profit,
        DENSE_RANK() OVER (ORDER BY cs.net_profit DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON c.c_customer_id = cs.c_customer_id
)
SELECT 
    w.w_warehouse_id,
    sh.total_sales,
    sh.total_profit,
    tc.c_customer_id,
    tc.ticket_count,
    tc.net_profit
FROM 
    warehouse w
LEFT JOIN 
    sales_hierarchy sh ON w.w_warehouse_sk = sh.ss_store_sk
LEFT JOIN 
    top_customers tc ON tc.rank <= 10
WHERE 
    w.w_country IS NOT NULL
    AND sh.total_profit > 0
    AND tc.ticket_count IS NOT NULL
ORDER BY 
    sh.total_profit DESC, tc.net_profit DESC
FETCH FIRST 100 ROWS ONLY;
