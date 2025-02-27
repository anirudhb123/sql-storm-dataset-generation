
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DistinctCustomers AS (
    SELECT 
        DISTINCT c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    WHERE 
        c.c_birth_country LIKE '%United States%'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        dc.c_customer_id,
        dc.c_first_name,
        dc.c_last_name,
        dc.full_address,
        dc.ca_city,
        dc.ca_state
    FROM 
        web_sales ws
    JOIN 
        DistinctCustomers dc ON ws.ws_bill_customer_sk = dc.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
AggregatedSales AS (
    SELECT 
        c.customer_id,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        COUNT(sd.ws_order_number) AS order_count,
        AVG(sd.ws_sales_price) AS average_sales_price
    FROM 
        SalesData sd
    JOIN 
        DistinctCustomers c ON sd.c_customer_id = c.c_customer_id
    GROUP BY 
        c.customer_id
)
SELECT 
    dc.c_first_name,
    dc.c_last_name,
    dc.full_address,
    as.total_sales,
    as.order_count,
    as.average_sales_price
FROM 
    AggregatedSales as
JOIN 
    DistinctCustomers dc ON as.customer_id = dc.c_customer_id
ORDER BY 
    as.total_sales DESC
LIMIT 10;
