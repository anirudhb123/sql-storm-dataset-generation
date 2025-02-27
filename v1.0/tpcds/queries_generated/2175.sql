
WITH recent_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        i_item_id, 
        i_product_name, 
        i_category, 
        total_quantity, 
        total_sales
    FROM 
        item i
    JOIN 
        recent_sales r ON i.i_item_sk = r.ws_item_sk
    WHERE 
        r.total_sales > (SELECT AVG(total_sales) FROM recent_sales)
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY d.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        d.cd_purchase_estimate IS NOT NULL
)
SELECT 
    hi.i_product_name AS product,
    hi.total_quantity AS quantity_sold,
    hi.total_sales AS sales_amount,
    cu.c_customer_id AS customer_id,
    cu.c_first_name AS first_name,
    cu.c_last_name AS last_name,
    cu.cd_gender AS gender,
    CASE 
        WHEN cu.cd_marital_status = 'M' THEN 'Married' 
        ELSE 'Single' 
    END AS marital_status,
    CASE 
        WHEN cu.purchase_rank <= 10 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_classification
FROM 
    high_value_items hi
JOIN 
    customer_data cu ON cu.cd_gender = (SELECT DISTINCT cd_gender FROM customer_demographics WHERE cd_demo_sk = cu.c_current_cdemo_sk)
WHERE 
    EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk IN (
            SELECT sr_store_sk 
            FROM store_returns 
            WHERE sr_item_sk = hi.i_item_sk
        )
    )
ORDER BY 
    hi.total_sales DESC, cu.c_last_name ASC
LIMIT 100;
