
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        ws.bill_customer_sk

    UNION ALL

    SELECT 
        ch.bill_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ch.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC)
    FROM 
        web_sales ws
    JOIN 
        customer ch ON ws.bill_customer_sk = ch.c_customer_sk
    JOIN 
        sales_hierarchy sh ON ch.c_customer_sk = sh.bill_customer_sk
    GROUP BY 
        ch.bill_customer_sk
)

SELECT 
    sh.bill_customer_sk,
    sh.total_sales,
    ca.city,
    ca.state,
    sm.sm_type,
    DENSE_RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    customer_address ca ON sh.bill_customer_sk = ca.ca_address_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (
        SELECT 
            ws.ship_mode_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.bill_customer_sk = sh.bill_customer_sk 
        LIMIT 1
    )
WHERE 
    sh.sales_rank <= 10
ORDER BY 
    sh.total_sales DESC
LIMIT 50;
