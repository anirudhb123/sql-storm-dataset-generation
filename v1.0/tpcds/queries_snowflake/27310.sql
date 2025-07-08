
WITH AddressInfo AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(ca_city, ', ') AS cities,
        LISTAGG(DISTINCT ca_street_name || ' ' || ca_street_number, ', ') AS street_details
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        LISTAGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesInfo AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        AVG(ws_sales_price) AS average_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    addr.ca_state,
    addr.address_count,
    addr.cities,
    cust.cd_gender,
    cust.customer_count,
    cust.total_dependents,
    cust.customer_names,
    sales.total_quantity_sold,
    sales.average_sales_price
FROM 
    AddressInfo addr
JOIN 
    CustomerInfo cust ON cust.customer_count > 0
LEFT JOIN 
    SalesInfo sales ON sales.ws_bill_cdemo_sk = cust.customer_count
ORDER BY 
    addr.address_count DESC, cust.customer_count DESC;
