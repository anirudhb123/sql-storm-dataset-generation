
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
OrderDetails AS (
    SELECT 
        COALESCE(ws.ws_bill_customer_sk, ss.ss_customer_sk) AS customer_sk,
        COALESCE(ws.ws_sales_price, ss.ss_sales_price) AS sales_price,
        COALESCE(ws.ws_ship_date_sk, ss.ss_sold_date_sk) AS sold_date_sk
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
),
AggregatedSales AS (
    SELECT 
        customer_sk,
        SUM(sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        MIN(sold_date_sk) AS first_order_date,
        MAX(sold_date_sk) AS last_order_date
    FROM 
        OrderDetails
    GROUP BY 
        customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    asales.total_sales,
    asales.total_orders,
    asales.first_order_date,
    asales.last_order_date
FROM 
    CustomerInfo ci
LEFT JOIN 
    AggregatedSales asales ON ci.c_customer_id = asales.customer_sk
WHERE 
    ci.cd_purchase_estimate > 5000
ORDER BY 
    asales.total_sales DESC, 
    ci.c_last_name ASC;
