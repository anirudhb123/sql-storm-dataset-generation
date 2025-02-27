
WITH AddressInfo AS (
    SELECT 
        ca_city, 
        ca_state, 
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city, 
        ca_state
),
SalesInfo AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
DateInfo AS (
    SELECT 
        d_date_sk, 
        d_day_name, 
        d_month_seq,
        d_year
    FROM 
        date_dim
)
SELECT 
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    a.ca_city,
    a.ca_state,
    a.customer_count,
    a.customer_names,
    s.total_sales,
    s.total_orders
FROM 
    DateInfo d
LEFT JOIN 
    SalesInfo s ON d.d_date_sk = s.ws_ship_date_sk
LEFT JOIN 
    AddressInfo a ON a.ca_city IS NOT NULL
ORDER BY 
    d.d_year, 
    d.d_month_seq, 
    a.ca_state;
