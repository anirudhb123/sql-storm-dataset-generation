
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS address_rank
    FROM 
        customer_address ca
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
total_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(sd.total_sales_price, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS order_count
    FROM 
        item item
    LEFT JOIN 
        sales_data sd ON item.i_item_sk = sd.ws_item_sk
),
final_results AS (
    SELECT 
        r.c_customer_id,
        a.ca_city,
        a.ca_state,
        s.total_sales,
        s.order_count
    FROM 
        ranked_customers r
    LEFT JOIN 
        customer_addresses a ON r.c_customer_sk = a.ca_address_sk AND a.address_rank = 1
    LEFT JOIN 
        total_sales s ON r.c_customer_id = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT i_item_sk FROM item) LIMIT 1)
    WHERE 
        r.purchase_rank <= 10
        AND (s.total_sales > (SELECT AVG(total_sales) FROM total_sales) OR s.total_sales IS NULL)
)
SELECT 
    f.c_customer_id,
    f.ca_city,
    f.ca_state,
    CASE 
        WHEN f.total_sales > 1000 THEN 'High Value'
        WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    (SELECT COUNT(*) FROM store_sales WHERE ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_category_id = 1)) AS store_sales_count,
    EXISTS (SELECT 1 FROM promotion p WHERE p.p_discount_active = 'Y' AND p.p_item_sk IN (SELECT i_item_sk FROM item)) AS active_promotions
FROM 
    final_results f
WHERE 
    f.ca_state IS NOT NULL
ORDER BY 
    f.total_sales DESC, 
    f.c_customer_id;
