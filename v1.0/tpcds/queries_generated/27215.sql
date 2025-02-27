
WITH Address_Stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        LISTAGG(ca_street_name, ', ') WITHIN GROUP (ORDER BY LENGTH(ca_street_name)) AS all_street_names
    FROM customer_address
    GROUP BY ca_state
), 
Customer_Demo AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
), 
Inventory_Stats AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT 
    A.ca_state, 
    A.total_addresses, 
    A.max_street_name_length, 
    A.min_street_name_length, 
    A.avg_street_name_length, 
    C.cd_gender, 
    C.total_customers, 
    C.avg_purchase_estimate, 
    I.total_quantity_on_hand
FROM Address_Stats A
JOIN Customer_Demo C ON A.ca_state IS NOT NULL
JOIN Inventory_Stats I ON I.inv_warehouse_sk IS NOT NULL
ORDER BY A.total_addresses DESC, C.total_customers DESC;
