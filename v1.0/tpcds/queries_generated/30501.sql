
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_birth_month = 12
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        s.ss_item_sk,
        s.ss_ticket_number,
        s.ss_store_sk,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
detailed_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        AVG(cr.cr_return_amt) AS avg_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ch.total_web_sales,
    ch.total_tickets,
    ms.total_sales,
    dr.total_returns,
    dr.avg_return_amount,
    COALESCE(ch.total_web_sales, 0) - COALESCE(dr.total_returns, 0) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ms.total_sales DESC) AS sales_rank
FROM 
    sales_hierarchy s
LEFT JOIN 
    customer_summary ch ON s.c_customer_sk = ch.cd_gender
LEFT JOIN 
    monthly_sales ms ON s.c_customer_sk = ms.d_month_seq
LEFT JOIN 
    detailed_returns dr ON s.c_customer_sk = dr.cr_item_sk
WHERE 
    s.level = 1
ORDER BY 
    net_sales DESC, sales_rank
LIMIT 100;
