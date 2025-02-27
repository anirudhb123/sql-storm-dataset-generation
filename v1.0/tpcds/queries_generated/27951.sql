
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomerByGender AS (
    SELECT 
        cd_gender,
        full_name,
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rnk <= 5
),
AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_city, ', ') AS cities_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ac.ca_state,
    ac.total_addresses,
    ac.cities_list,
    tc.cd_gender,
    tc.full_name,
    tc.cd_purchase_estimate,
    ss.total_orders,
    ss.total_net_profit
FROM 
    AddressSummary ac
JOIN 
    TopCustomerByGender tc ON ac.ca_state IN ('CA', 'NY')
JOIN 
    SalesStats ss ON ss.total_orders > 50
ORDER BY 
    ac.total_addresses DESC, 
    tc.cd_purchase_estimate DESC;
