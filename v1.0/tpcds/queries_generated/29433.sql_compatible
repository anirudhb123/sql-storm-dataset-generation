
WITH AddressDetails AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        COUNT(DISTINCT c.customer_id) AS total_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state, ca.street_number, ca.street_name, ca.street_type
),
SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    dd.d_date AS sale_date,
    ad.address_city,
    ad.address_state,
    ad.full_address,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    ad.total_customers
FROM 
    date_dim dd
LEFT JOIN 
    SalesSummary ss ON dd.d_date_sk = ss.ws_ship_date_sk
LEFT JOIN 
    AddressDetails ad ON ad.address_city = dd.d_day_name
WHERE 
    dd.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    dd.d_date, ad.address_city, ad.address_state;
