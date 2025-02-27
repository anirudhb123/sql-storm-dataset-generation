
WITH customer_full_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        wes.ws_order_number,
        wes.ws_item_sk,
        wes.ws_quantity,
        wes.ws_sales_price,
        wes.ws_net_paid,
        wes.ws_ship_date_sk,
        d.d_date AS ship_date
    FROM 
        web_sales wes
    JOIN 
        date_dim d ON wes.ws_ship_date_sk = d.d_date_sk
),
purchase_summary AS (
    SELECT 
        cfi.c_customer_id,
        cfi.full_name,
        SUM(si.ws_quantity) AS total_quantity,
        SUM(si.ws_sales_price) AS total_sales,
        SUM(si.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT si.ws_order_number) AS total_orders
    FROM 
        customer_full_info cfi
    LEFT JOIN 
        sales_info si ON cfi.c_customer_id = si.ws_bill_customer_sk
    GROUP BY 
        cfi.c_customer_id, cfi.full_name
)
SELECT 
    ps.full_name,
    ps.total_quantity,
    ps.total_sales,
    ps.total_net_paid,
    ps.total_orders,
    CASE 
        WHEN ps.total_net_paid > 1000 THEN 'High Value'
        WHEN ps.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    purchase_summary ps
WHERE 
    ps.total_orders > 0
ORDER BY 
    ps.total_net_paid DESC;
