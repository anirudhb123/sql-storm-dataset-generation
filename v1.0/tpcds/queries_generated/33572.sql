
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_brand,
        i_current_price
    FROM 
        item
),
customer_data AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        COALESCE(NULLIF(cd_credit_rating, ''), 'Not Rated') AS clean_credit_rating
    FROM 
        customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
filtered_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        i.i_item_desc,
        i.i_brand,
        c.cd_gender,
        c.clean_credit_rating
    FROM 
        sales_summary s
    JOIN item_details i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN customer_data c ON s.ws_item_sk IN (
        SELECT ws_item_sk
        FROM web_sales
        WHERE ws_quantity > 10
    )
    WHERE 
        s.rn <= 5
)
SELECT 
    fs.i_item_desc,
    fs.i_brand,
    SUM(fs.total_sales) AS total_sales,
    COUNT(fs.clean_credit_rating) AS customer_count,
    COUNT(DISTINCT fs.cd_gender) AS unique_genders
FROM 
    filtered_sales fs
GROUP BY 
    fs.i_item_desc, fs.i_brand
ORDER BY 
    total_sales DESC
LIMIT 10;
