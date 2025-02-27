
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        IF(cd.cd_marital_status = 'M', 'Married', 'Single') AS marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.marital_status,
    ss.total_sales,
    ss.order_count,
    COALESCE(ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC), 0) AS sales_rank,
    CASE 
        WHEN ss.total_sales > 5000 THEN 'High'
        WHEN ss.total_sales BETWEEN 2000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    customer_details cd
LEFT JOIN 
    sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.order_count IS NOT NULL AND (cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 100)
ORDER BY 
    ss.total_sales DESC, cd.full_name ASC
LIMIT 10
UNION ALL
SELECT 
    'Aggregate' AS full_name,
    NULL AS cd_gender,
    NULL AS marital_status,
    SUM(ss.total_sales) AS total_sales,
    COUNT(ss.order_count) AS total_orders,
    NULL AS sales_rank,
    CASE 
        WHEN SUM(ss.total_sales) > 50000 THEN 'High'
        WHEN SUM(ss.total_sales) BETWEEN 20000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    sales_summary ss
WHERE 
    ss.sales_rank <= 10;
