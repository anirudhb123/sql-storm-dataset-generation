
WITH RECURSIVE category_sales AS (
    SELECT 
        i_category,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        item
    JOIN 
        store_sales ON item.i_item_sk = store_sales.ss_item_sk
    JOIN 
        date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        i_category
    UNION ALL
    SELECT 
        'Total' AS i_category,
        SUM(total_sales) AS total_sales,
        SUM(total_transactions) AS total_transactions
    FROM 
        category_sales
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cw.total_web_sales, 0) AS total_web_sales,
        COALESCE(ca.total_sales, 0) AS total_category_sales
    FROM 
        customer_sales cw
    LEFT JOIN 
        high_value_customers cs ON cw.c_customer_sk = cs.c_customer_sk
    LEFT JOIN 
        category_sales ca ON cs.c_customer_sk IS NOT NULL
)
SELECT 
    ss.c_first_name,
    ss.c_last_name,
    ss.total_web_sales,
    ss.total_category_sales,
    CASE 
        WHEN ss.total_web_sales = 0 THEN NULL
        ELSE ss.total_category_sales / ss.total_web_sales 
    END AS sales_ratio
FROM 
    sales_summary ss
WHERE 
    ss.total_web_sales > 500
ORDER BY 
    sales_ratio DESC;
