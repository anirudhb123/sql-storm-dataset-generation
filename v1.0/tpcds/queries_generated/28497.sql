
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        cd_marital_status,
        STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_current_price, ')'), ', ') AS sold_items
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year
)

SELECT 
    a.ca_state, 
    a.address_count, 
    a.full_addresses,
    c.cd_gender, 
    c.cd_marital_status, 
    c.customer_names,
    s.d_year, 
    s.total_sales, 
    s.sold_items
FROM AddressStats a
JOIN CustomerStats c ON a.address_count > 10
JOIN SalesStats s ON s.total_sales > 10000
ORDER BY a.ca_state, c.cd_gender, s.d_year;
