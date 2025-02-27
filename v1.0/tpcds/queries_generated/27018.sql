
WITH CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        can.gmt_offset AS gmt_offset
    FROM 
        customer_address ca
    INNER JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        warehouse w ON w.w_warehouse_sk = c.c_current_cdemo_sk
    WHERE 
        ca.ca_country = 'USA'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
BenchmarkedData AS (
    SELECT 
        ca.full_name,
        ca.ca_city,
        ca.ca_state,
        SUM(sd.total_quantity) AS quantity_sum,
        SUM(sd.total_net_paid) AS net_paid_sum,
        AVG(COALESCE(sd.total_net_paid, 0)) AS avg_net_paid
    FROM 
        CustomerAddressInfo ca 
    LEFT JOIN 
        SalesData sd ON ca.ca_address_id = sd.ws_order_number
    GROUP BY 
        ca.full_name, 
        ca.ca_city, 
        ca.ca_state
)
SELECT 
    *,
    CASE 
        WHEN avg_net_paid > 100 THEN 'High Value'
        WHEN avg_net_paid BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    BenchmarkedData
ORDER BY 
    quantity_sum DESC, 
    net_paid_sum DESC;
