
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        'N/A' AS parent_customer,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        sh.c_first_name || ' ' || sh.c_last_name AS parent_customer,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer ch
    JOIN 
        sales_hierarchy sh ON sh.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN 
        web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, sh.c_first_name, sh.c_last_name
),

recent_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date >= DATE '2002-10-01' - INTERVAL '30 day'
    GROUP BY 
        ws.ws_sold_date_sk
),

filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        MAX(sh.total_sales) AS max_sales
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    WHERE 
        sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    COALESCE(r.total_net_paid, 0) AS total_recent_sales,
    fc.max_sales
FROM 
    filtered_customers fc
LEFT JOIN 
    recent_sales r ON r.ws_sold_date_sk = (
        SELECT 
            MAX(ws_sold_date_sk) 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = fc.c_customer_sk
    )
ORDER BY 
    total_recent_sales DESC, max_sales DESC;
