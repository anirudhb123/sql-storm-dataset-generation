
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS item_rank
    FROM 
        item i
    JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender, 
    pi.i_item_desc,
    pi.total_quantity,
    pi.total_sales,
    CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    CASE 
        WHEN pi.item_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS item_status
FROM 
    customer_info ci
JOIN 
    popular_items pi ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = pi.i_item_sk LIMIT 1)
WHERE 
    ci.gender_rank <= 50
ORDER BY 
    pi.total_sales DESC, 
    ci.c_last_name ASC
LIMIT 100;
