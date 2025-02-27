
WITH Enhanced_Customer AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        (CASE 
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END) AS purchase_category,
        CONCAT(c.c_street_number, ' ', c.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Product_Analysis AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name, i.i_brand
),
Sales_Summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    ec.c_customer_id,
    ec.full_name,
    ec.cd_gender,
    ec.cd_marital_status,
    ec.ca_city,
    ec.ca_state,
    ec.ca_zip,
    ec.purchase_category,
    ec.full_address,
    ec.c_email_address,
    pa.i_product_name,
    pa.avg_sales_price,
    pa.total_sales,
    ss.total_revenue,
    ss.total_orders,
    ROW_NUMBER() OVER (PARTITION BY ec.c_customer_id ORDER BY pa.total_sales DESC) AS ranking
FROM 
    Enhanced_Customer ec
JOIN 
    Product_Analysis pa ON ec.c_customer_id = pa.i_item_id
JOIN 
    Sales_Summary ss ON ss.d_year = 2023 -- Replace with the desired year for analysis
WHERE 
    ec.ca_state = 'CA' AND 
    ec.cd_gender = 'F' AND 
    ec.purchase_category = 'High'
ORDER BY 
    ranking;
