
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1) AS word_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_quantity) AS avg_items_per_order,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)

SELECT 
    AS.address_count,
    AS.avg_street_name_length,
    AS.word_count,
    CS.customer_count,
    CS.avg_dependents,
    CS.max_purchase_estimate,
    SS.total_sales,
    SS.avg_items_per_order,
    SS.total_orders
FROM 
    AddressStats AS
JOIN 
    CustomerStats CS ON AS.address_count > 1000
JOIN 
    SalesStats SS ON SS.total_sales > 1000000
ORDER BY 
    AS.address_count DESC;
