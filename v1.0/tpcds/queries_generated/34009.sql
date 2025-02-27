
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependents
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), active_customers AS (
    SELECT 
        customer_details.c_customer_id,
        customer_details.c_first_name,
        customer_details.c_last_name,
        sales_summary.total_quantity,
        sales_summary.total_sales,
        sales_summary.sales_rank
    FROM 
        customer_details
    JOIN 
        sales_summary ON customer_details.c_customer_id = sales_summary.ws_bill_customer_sk
    WHERE 
        sales_summary.total_sales > 1000
    ORDER BY 
        sales_summary.total_sales DESC
)
SELECT 
    ac.c_customer_id,
    ac.c_first_name,
    ac.c_last_name,
    ac.total_quantity,
    ac.total_sales,
    ac.sales_rank,
    CASE 
        WHEN ac.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    active_customers ac
LEFT JOIN 
    customer_address ca ON ac.c_customer_id = ca.ca_address_sk
WHERE 
    ac.total_quantity IS NOT NULL
    AND (ca.ca_country IS NULL OR ca.ca_country <> 'US')
ORDER BY 
    ac.total_sales DESC
LIMIT 50;
