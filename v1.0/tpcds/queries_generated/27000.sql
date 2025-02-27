
WITH demographics AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        CASE 
            WHEN cd.cd_purchase_estimate > 500 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low' 
        END AS purchase_band
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_items
    FROM web_sales ws
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk
),
joined_data AS (
    SELECT 
        d.full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.ca_city,
        d.ca_state,
        d.ca_country,
        d.purchase_band,
        s.total_sales,
        s.number_of_items,
        DENSE_RANK() OVER (PARTITION BY d.purchase_band ORDER BY s.total_sales DESC) AS sales_rank
    FROM demographics d
    JOIN sales s ON d.c_customer_id = s.ws_order_number
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    purchase_band,
    total_sales,
    number_of_items,
    sales_rank
FROM joined_data
WHERE sales_rank <= 10
ORDER BY purchase_band, total_sales DESC;
