
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        STRING_AGG(DISTINCT CONCAT(ic.i_item_desc, ' (', ic.i_item_id, ')'), ', ') AS purchased_items
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        (SELECT sr.customer_sk AS sr_customer_sk, i.i_item_desc, i.i_item_id
         FROM store_returns sr 
         JOIN item i ON sr.sr_item_sk = i.i_item_sk) AS ic ON ic.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, ca.ca_country
),
AggregatedInfo AS (
    SELECT 
        ci.ca_state,
        ci.cd_gender,
        COUNT(ci.c_customer_id) AS total_customers,
        STRING_AGG(ci.full_name, '; ') AS customer_names,
        STRING_AGG(DISTINCT ci.purchased_items, '; ') AS all_items_purchased
    FROM 
        CustomerInfo ci
    GROUP BY 
        ci.ca_state, ci.cd_gender
)
SELECT 
    ai.ca_state,
    ai.cd_gender,
    ai.total_customers,
    ai.customer_names,
    ai.all_items_purchased,
    ROW_NUMBER() OVER (ORDER BY ai.total_customers DESC) AS ranking
FROM 
    AggregatedInfo ai
ORDER BY 
    ai.total_customers DESC;
