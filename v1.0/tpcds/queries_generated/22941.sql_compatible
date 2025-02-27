
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.edu_count AS education_count,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CASE 
                WHEN cd.cd_dep_count > 3 THEN 'Large Family'
                WHEN cd.cd_dep_count = 0 THEN 'Single'
                ELSE 'Small Family'
            END
        END AS family_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_sales_customers AS (
    SELECT 
        ci.c_customer_sk,
        si.total_sales,
        si.order_count
    FROM 
        customer_info ci
    JOIN 
        sales_summary si ON ci.c_customer_sk IN (
            SELECT DISTINCT ws_bill_customer_sk 
            FROM web_sales 
            WHERE ws_sold_date_sk BETWEEN 1 AND 30 
            INTERSECT
            SELECT DISTINCT sr_customer_sk 
            FROM store_returns 
            WHERE sr_return_date_sk > 0
        )
    WHERE 
        si.total_sales > 5000
),
average_order_value AS (
    SELECT 
        ci.c_customer_sk,
        AVG(si.total_sales / NULLIF(si.order_count, 0)) AS avg_order_value
    FROM 
        high_sales_customers ci
    JOIN 
        sales_summary si ON ci.c_customer_sk = si.ws_item_sk
    GROUP BY 
        ci.c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.family_status,
    a.avg_order_value,
    RANK() OVER (ORDER BY a.avg_order_value DESC) AS ranking
FROM 
    customer_info ci
JOIN 
    average_order_value a ON ci.c_customer_sk = a.c_customer_sk
WHERE 
    (ci.cd_gender IS NOT NULL OR ci.family_status IS NOT NULL)
    AND (a.avg_order_value > 100 OR ci.cd_marital_status = 'M')
ORDER BY 
    ranking, ci.c_customer_sk;
