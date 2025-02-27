
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type), ', ') AS example_addresses,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        STRING_AGG(c_first_name || ' ' || c_last_name, ', ') AS example_customers
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    AS.address_state,
    AS.total_addresses,
    AS.example_addresses,
    CS.cd_gender,
    CS.total_customers,
    CS.total_dependents,
    CS.example_customers,
    SS.total_sales,
    SS.average_profit,
    SS.unique_customers
FROM 
    AddressStats AS
JOIN 
    CustomerStats AS CS ON 1=1 
JOIN 
    SalesSummary AS SS ON 1=1
ORDER BY 
    AS.total_addresses DESC, 
    CS.total_customers DESC, 
    SS.total_sales DESC
LIMIT 100;
