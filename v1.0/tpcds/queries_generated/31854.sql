
WITH RECURSIVE income_hist AS (
    SELECT 
        hd_demo_sk, 
        hd_income_band_sk, 
        1 AS level
    FROM 
        household_demographics
    WHERE 
        hd_income_band_sk IS NOT NULL
    UNION ALL
    SELECT 
        h.hd_demo_sk, 
        h.hd_income_band_sk, 
        ih.level + 1
    FROM 
        household_demographics h
    JOIN 
        income_hist ih ON h.hd_demo_sk = ih.hd_demo_sk
    WHERE 
        ih.level < 5
),
sales_summary AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) as sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
date_filter AS (
    SELECT 
        d.d_date_sk 
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023 AND 
        d.d_moy = 3
),
returned_sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_net_paid) AS total_returned
    FROM 
        web_sales ws
    JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
    WHERE 
        wr.wr_returned_date_sk IN (SELECT d.d_date_sk FROM date_filter d)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cs.total_sales,
    r.total_returned,
    COALESCE(cs.total_sales - r.total_returned, cs.total_sales) AS net_sales,
    CASE 
        WHEN cs.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    sales_summary cs
LEFT JOIN 
    returned_sales r ON cs.c_customer_sk = r.ws_item_sk
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M'
ORDER BY 
    net_sales DESC;
