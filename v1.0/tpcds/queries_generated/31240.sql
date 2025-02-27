
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
),
customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity,
    cs.total_sales,
    ir.i_item_id,
    ir.i_product_name
FROM 
    item_summary cs
JOIN 
    customer_rank cr ON cr.rank_by_gender <= 10 AND cr.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_item_sk = cs.i_item_sk
        AND ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2022
        )
    )
LEFT JOIN 
    item ir ON ir.i_item_sk = cs.i_item_sk
WHERE 
    cs.total_sales > 500
ORDER BY 
    cs.total_sales DESC, cr.c_last_name ASC;
