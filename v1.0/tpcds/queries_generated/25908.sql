
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year) AS age_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_item_sk) AS items_sold,
        dt.d_date AS sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
    GROUP BY 
        ws.ws_order_number, dt.d_date
),
RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.full_name,
        SUM(si.total_sales) AS customer_total_sales,
        COUNT(si.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.age_rank ORDER BY SUM(si.total_sales) DESC) AS sales_rank
    FROM 
        CustomerInfo c
    LEFT JOIN 
        SalesInfo si ON c.c_customer_id = si.ws_order_number
    GROUP BY 
        c.c_customer_id, c.full_name, c.age_rank
)
SELECT 
    r.full_name,
    r.customer_total_sales,
    r.total_orders,
    r.sales_rank,
    r.age_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.customer_total_sales DESC;
