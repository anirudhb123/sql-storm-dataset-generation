
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_order_number) AS row_num
    FROM 
        web_sales ws
    WHERE 
        ws_sales_price > 50
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count > 2
),
returns_info AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        SUM(cr.cr_return_amt) AS total_returned_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
joined_info AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ss.ws_order_number,
        ss.ws_quantity,
        ss.ws_sales_price,
        ri.total_returns,
        ri.total_returned_amt
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.web_site_sk
    LEFT JOIN 
        returns_info ri ON ci.c_customer_sk = ri.returning_customer_sk
)
SELECT 
    j.c_first_name,
    j.c_last_name,
    j.cd_gender,
    COALESCE(j.ws_order_number, 'No Orders') AS order_number,
    COALESCE(j.ws_quantity, 0) AS quantity_sold,
    COALESCE(j.ws_sales_price, 0.00) AS sales_price,
    j.total_returns,
    j.total_returned_amt
FROM 
    joined_info j
WHERE 
    j.gender_rank <= 10
ORDER BY 
    j.cd_gender, j.c_last_name;
