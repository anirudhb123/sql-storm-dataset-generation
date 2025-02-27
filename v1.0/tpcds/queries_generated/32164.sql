
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_bill_customer_sk,
        1 AS level
    FROM web_sales
    GROUP BY ws_item_sk, ws_bill_customer_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        cs_bill_customer_sk,
        level + 1
    FROM catalog_sales
    JOIN sales_summary ON sales_summary.ws_item_sk = cs_item_sk
    GROUP BY cs_item_sk, cs_bill_customer_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
    WHERE cd_marital_status = 'M'
),
total_sales_by_customer AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ts.total_sales,
        ts.order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ts.total_sales DESC) AS rnk
    FROM customer c
    JOIN total_sales_by_customer ts ON c.c_customer_sk = ts.bill_customer_sk
    WHERE ts.total_sales > (SELECT AVG(total_sales) FROM total_sales_by_customer)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    SUM(ss.total_quantity) AS total_quantity_sold,
    MAX(ss.total_sales) AS max_sales,
    CASE 
        WHEN COUNT(DISTINCT ss.ws_item_sk) > 10 THEN 'High Variety'
        ELSE 'Low Variety'
    END AS variety_status
FROM high_value_customers hvc
JOIN customer_demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN sales_summary ss ON hvc.c_customer_sk = ss.ws_bill_customer_sk
WHERE hvc.order_count > 5
GROUP BY c.c_first_name, c.c_last_name, cd.cd_gender
HAVING SUM(ss.total_quantity) IS NOT NULL
ORDER BY max_sales DESC
LIMIT 100;
