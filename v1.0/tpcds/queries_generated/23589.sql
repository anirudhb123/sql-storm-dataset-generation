
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY
        ws_item_sk
),
item_info AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_brand,
        i_category,
        i_current_price,
        CASE 
            WHEN i_current_price IS NULL THEN 'N/A'
            ELSE i_current_price::varchar
        END AS current_price_str
    FROM 
        item
),
address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
filtered_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_ship_date_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        CASE 
            WHEN ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales) THEN 'Above Average'
            WHEN ws.ws_sales_price < (SELECT AVG(ws_sales_price) FROM web_sales) THEN 'Below Average'
            ELSE 'Average'
        END AS price_category
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IN (SELECT DISTINCT ws_ship_date_sk FROM web_sales WHERE ws_sales_price IS NOT NULL)
)
SELECT 
    ii.i_item_id,
    ii.i_brand,
    ii.i_category,
    ii.current_price_str,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(f.price_category, 'N/A') AS price_category,
    ci.c_first_name,
    ci.c_last_name,
    ai.full_address,
    COUNT(*) OVER (PARTITION BY ci.cd_gender) AS total_customers_by_gender
FROM 
    item_info ii
LEFT JOIN 
    ranked_sales r ON ii.i_item_sk = r.ws_item_sk AND r.sales_rank = 1
LEFT JOIN 
    filtered_sales f ON ii.i_item_sk = f.ws_item_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ii.i_item_sk)
LEFT JOIN 
    address_info ai ON ai.ca_address_sk IN (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = ci.c_customer_sk)
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
    AND (ii.i_current_price < 50 OR ii.i_current_price IS NULL)
ORDER BY 
    total_sales DESC, ii.i_item_id ASC
FETCH FIRST 100 ROWS ONLY;
