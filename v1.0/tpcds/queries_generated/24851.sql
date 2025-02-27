
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        ws.ws_item_sk
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(NULLIF(SUM(ss.ss_quantity), 0), 1) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    is.total_sales,
    si.s_store_name,
    si.total_sales AS store_sales,
    CASE 
        WHEN si.total_sales > 500 THEN 'High Seller'
        WHEN si.total_sales BETWEEN 200 AND 500 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS seller_status
FROM 
    ranked_customers rc
JOIN 
    item_sales is ON rc.c_customer_sk = is.ws_item_sk
JOIN 
    store_info si ON si.total_sales = (
        SELECT MAX(total_sales) 
        FROM store_info
        WHERE total_sales IS NOT NULL
    )
WHERE 
    rc.gender_rank = 1
    AND rc.cd_marital_status IN ('S', 'M')
    AND NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = is.ws_item_sk 
        AND inv.inv_quantity_on_hand < 10
    )
ORDER BY 
    is.total_sales DESC,
    rc.c_last_name ASC;
