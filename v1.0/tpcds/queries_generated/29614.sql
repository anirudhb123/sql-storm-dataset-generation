
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_quantity_on_hand,
        AVG(inv.inv_quantity_on_hand) OVER () AS avg_quantity
    FROM 
        inventory inv
),
demographic_summary AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.purchase_estimate_category,
        ci.ca_city,
        ci.ca_state,
        SUBSTRING(ci.email_domain, 1, POSITION('.' IN ci.email_domain) - 1) AS email_prefix,
        SUM(CASE WHEN inv.inv_quantity_on_hand < inv_summary.avg_quantity THEN 1 ELSE 0 END) AS below_average_inventory_count
    FROM 
        customer_info ci
    LEFT JOIN 
        inventory_summary inv_summary ON TRUE
    LEFT JOIN 
        inventory inv ON ci.c_customer_id = CAST(CONCAT('CUST_', inv.inv_item_sk) AS CHAR(16))
    GROUP BY 
        ci.c_customer_id, ci.full_name, ci.cd_gender, ci.cd_marital_status, 
        ci.purchase_estimate_category, ci.ca_city, ci.ca_state, 
        email_prefix
)
SELECT 
    ds.full_name,
    ds.cd_gender,
    ds.purchase_estimate_category,
    ds.ca_city,
    ds.ca_state,
    ds.email_prefix,
    ds.below_average_inventory_count
FROM 
    demographic_summary ds
WHERE 
    ds.below_average_inventory_count > 0
ORDER BY 
    ds.purchase_estimate_category DESC, ds.full_name ASC;
