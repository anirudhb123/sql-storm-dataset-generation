
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesDetails AS (
    SELECT 
        cs.c_customer_id,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cs.total_orders,
        cs.total_sales,
        RANK() OVER (PARTITION BY ad.ca_state ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        AddressDetails ad ON ad.full_address = CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)
)
SELECT 
    sd.c_customer_id,
    sd.full_address,
    sd.ca_city,
    sd.ca_state,
    sd.ca_zip,
    sd.total_orders,
    sd.total_sales,
    sd.sales_rank
FROM 
    SalesDetails sd
WHERE 
    sd.sales_rank <= 10
ORDER BY 
    sd.ca_state, sd.sales_rank;
