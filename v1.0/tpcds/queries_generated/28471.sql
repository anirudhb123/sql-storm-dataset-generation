
WITH StringBenchmark AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count,
        STRING_AGG(DISTINCT ca.ca_street_name || ', ' || ca.ca_city || ', ' || ca.ca_state, '; ') AS addresses,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT i.i_item_desc, ', ') AS item_descriptions
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        inventory inv ON inv.inv_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_brand LIKE 'Brand%')
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        full_name
)
SELECT 
    full_name, 
    warehouse_count, 
    addresses, 
    avg_purchase_estimate, 
    item_descriptions
FROM 
    StringBenchmark
WHERE 
    LENGTH(full_name) > 20
ORDER BY 
    avg_purchase_estimate DESC;
