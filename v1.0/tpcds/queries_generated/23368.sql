
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS row_num
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 
),
address_info AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM 
        customer_address 
    WHERE 
        ca_country = 'USA'
),
aggregated_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_revenue
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
),
ranked_addresses AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        ai.ca_address_sk,
        ai.city_rank,
        ROW_NUMBER() OVER (ORDER BY ai.city_rank) AS addr_rank
    FROM 
        address_info ai
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ra.ca_city,
    ra.ca_state,
    ra.ca_address_sk,
    as.total_quantity,
    as.total_revenue,
    CASE 
        WHEN as.total_revenue > 5000 THEN 'High Value'
        WHEN as.total_revenue BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_method,
    CASE 
        WHEN ra.ca_city IS NULL THEN 'City Not Found'
        ELSE 'City Found'
    END AS city_found
FROM 
    customer_info ci
INNER JOIN 
    aggregated_sales as ON as.ws_order_number = ci.c_customer_sk
LEFT JOIN 
    ranked_addresses ra ON ra.ca_address_sk = ci.c_current_addr_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (
        SELECT 
            sm_ship_mode_sk 
        FROM 
            ship_mode 
        WHERE 
            sm_code = (
                SELECT 
                    DISTINCT sm_code 
                FROM 
                    ship_mode 
                WHERE 
                    sm_carrier LIKE '%FedEx%'
                LIMIT 1
            )
    )
WHERE 
    (ci.cd_dep_count IS NULL OR ci.cd_dep_count > 2)
    AND ra.city_rank <= 10
ORDER BY 
    customer_value DESC, 
    ci.c_last_name ASC NULLS LAST;
