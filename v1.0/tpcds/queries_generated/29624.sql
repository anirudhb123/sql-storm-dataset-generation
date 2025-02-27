
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, ''), ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
DemographicStats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
),
DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        EXTRACT(YEAR FROM d_date) AS year,
        EXTRACT(MONTH FROM d_date) AS month,
        EXTRACT(DAY FROM d_date) AS day,
        COUNT(*) AS total_dates
    FROM 
        date_dim
    GROUP BY 
        d_date_sk, d_date
),
WarehouseSummary AS (
    SELECT 
        w_warehouse_sk,
        w_warehouse_name,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        warehouse
    JOIN 
        inventory ON warehouse.w_warehouse_sk = inventory.inv_warehouse_sk
    GROUP BY 
        w_warehouse_sk, w_warehouse_name
)
SELECT 
    a.full_address,
    d.avg_purchase_estimate,
    d.marital_statuses,
    dt.year,
    dt.month,
    ws.total_quantity_on_hand
FROM 
    AddressConcat a
JOIN 
    DemographicStats d ON a.ca_address_sk = d.cd_demo_sk
JOIN 
    DateDetails dt ON d.demographic_count > 0
JOIN 
    WarehouseSummary ws ON ws.total_quantity_on_hand > 100
WHERE 
    a.full_address LIKE '%New York%'
ORDER BY 
    dt.year DESC, dt.month DESC, ws.total_quantity_on_hand DESC;
