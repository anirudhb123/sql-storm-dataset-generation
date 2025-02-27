
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
AggregatedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    a.ca_state,
    a.address_count,
    a.min_zip,
    a.max_zip,
    a.cities,
    a.street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.customer_count,
    c.total_dependents,
    c.avg_purchase_estimate,
    s.w_warehouse_id,
    s.total_net_profit,
    s.order_count,
    s.total_quantity_sold
FROM 
    AddressStats a
CROSS JOIN 
    CustomerDemographics c
CROSS JOIN 
    AggregatedSales s
WHERE 
    a.address_count > 100 AND 
    c.customer_count > 50;
