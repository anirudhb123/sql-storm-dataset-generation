
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451912 AND 2451918 
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
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 200 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 201 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.purchase_category,
    rs.total_quantity,
    rs.total_sales
FROM 
    customer_info ci
JOIN 
    ranked_sales rs ON ci.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = rs.ws_item_sk 
        LIMIT 1
    )
WHERE 
    rs.rank = 1
ORDER BY 
    rs.total_sales DESC
LIMIT 100;
