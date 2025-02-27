
WITH RECURSIVE sales_growth AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS row_num
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        t.ws_sold_date_sk,
        SUM(t.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY t.ws_sold_date_sk) AS row_num
    FROM 
        web_sales t
    JOIN 
        sales_growth sg ON t.ws_sold_date_sk = sg.ws_sold_date_sk + INTERVAL '1 DAY'
    GROUP BY 
        t.ws_sold_date_sk
),
sales_summary AS (
    SELECT 
        d.d_year,
        COALESCE(SUM(sg.total_sales), 0) AS annual_sales,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        date_dim d
    LEFT JOIN 
        sales_growth sg ON d.d_date_sk = sg.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
avg_customer_spending AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss_net_paid), 0) AS total_spending,
        COUNT(ss_ticket_number) AS order_count,
        CASE 
            WHEN COUNT(ss_ticket_number) > 0 THEN COALESCE(SUM(ss_net_paid) / COUNT(ss_ticket_number), 0)
            ELSE 0 
        END AS avg_spending
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ss.d_year,
    ss.annual_sales,
    ss.unique_customers,
    a.avg_spending
FROM 
    sales_summary ss
LEFT JOIN 
    (SELECT 
         ROW_NUMBER() OVER (ORDER BY total_spending DESC) AS rank,
         total_spending,
         avg_spending
     FROM 
         avg_customer_spending
     WHERE 
         avg_spending IS NOT NULL
     ) a ON a.rank = 1
WHERE 
    ss.d_year IS NOT NULL
ORDER BY 
    ss.d_year DESC
LIMIT 10;
