
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender
),
InventorySummary AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_item_sk) AS unique_item_count
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
)
SELECT 
    a.ca_state,
    a.address_count,
    a.cities,
    a.street_names,
    cd.gender,
    cd.customer_count,
    cd.avg_purchase_estimate,
    i.total_quantity,
    i.unique_item_count
FROM 
    AddressCounts a
JOIN 
    CustomerDemographics cd ON cd.customer_count > 100
JOIN 
    InventorySummary i ON i.total_quantity > 1000
ORDER BY 
    a.address_count DESC, 
    cd.customer_count DESC;
