
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        ISNULL(is.total_quantity, 0) AS total_quantity,
        ISNULL(is.total_sales, 0) AS total_sales,
        RANK() OVER (ORDER BY ISNULL(is.total_sales, 0) DESC) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_sales
FROM 
    ranked_customers rc
CROSS JOIN 
    top_items ti
WHERE 
    rc.rank <= 10
    AND ti.sales_rank <= 5
ORDER BY 
    rc.cd_gender,
    ti.total_sales DESC;
