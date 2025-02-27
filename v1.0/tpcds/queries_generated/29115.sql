
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) END, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        cd_gender,
        cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        w.w_warehouse_name,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
), AggregatedSales AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.full_address,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS order_count,
        MIN(sd.d_date) AS first_purchase_date,
        MAX(sd.d_date) AS last_purchase_date
    FROM 
        CustomerInfo ci
    JOIN 
        SalesDetails sd ON ci.c_customer_id = sd.ws_order_number
    GROUP BY 
        ci.c_customer_id, ci.full_name, ci.full_address
)
SELECT 
    *,
    DATEDIFF(last_purchase_date, first_purchase_date) AS days_between_purchases,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_category
FROM 
    AggregatedSales
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;
