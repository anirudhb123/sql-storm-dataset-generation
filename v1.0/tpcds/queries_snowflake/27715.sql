
WITH address_summary AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(CONCAT(ca_street_name, ' ', ca_street_type, ' ', ca_street_number), ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state, 
        ca_city
),
customer_info AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS gender_count,
        LISTAGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer_demographics 
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_data AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        LISTAGG(CAST(ws_item_sk AS VARCHAR), ', ') AS sold_items
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
final_summary AS (
    SELECT 
        a.ca_state,
        a.ca_city,
        a.address_count,
        a.full_address_list,
        c.cd_gender,
        c.gender_count,
        c.customer_names,
        s.total_sales,
        s.sold_items
    FROM 
        address_summary a
    LEFT JOIN 
        customer_info c ON a.ca_city = (SELECT ca_city FROM customer_address WHERE ca_state = a.ca_state LIMIT 1)
    LEFT JOIN 
        sales_data s ON s.ws_ship_date_sk = (SELECT ws_ship_date_sk FROM web_sales LIMIT 1)
)
SELECT 
    fs.ca_state,
    fs.ca_city,
    fs.address_count,
    fs.full_address_list,
    fs.cd_gender,
    fs.gender_count,
    fs.customer_names,
    fs.total_sales,
    fs.sold_items
FROM 
    final_summary fs
ORDER BY 
    fs.total_sales DESC, fs.address_count ASC;
