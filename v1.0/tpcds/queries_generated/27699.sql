
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COUNT(ss.ss_item_sk) AS sales_count
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        sales_count DESC
    LIMIT 10
),
CustomerPurchases AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        pi.i_item_id,
        pi.i_item_desc
    FROM 
        CustomerInfo ci
    JOIN 
        store_sales ss ON ci.c_customer_id = ss.ss_customer_sk
    JOIN 
        PopularItems pi ON ss.ss_item_sk = pi.i_item_id
)
SELECT 
    cu.full_name,
    cu.ca_city,
    cu.ca_state,
    GROUP_CONCAT(DISTINCT pu.i_item_desc ORDER BY pu.i_item_desc ASC) AS purchased_items
FROM 
    CustomerInfo cu
LEFT JOIN 
    CustomerPurchases pu ON cu.c_customer_id = pu.c_customer_id
GROUP BY 
    cu.full_name, cu.ca_city, cu.ca_state
ORDER BY 
    cu.ca_state, cu.full_name;
