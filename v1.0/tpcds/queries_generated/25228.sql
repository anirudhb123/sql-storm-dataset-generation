
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ca.ca_state,
        COUNT(ca.ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS unique_cities
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    asum.address_count,
    asum.unique_cities,
    ss.total_sales_profit,
    ss.total_orders
FROM 
    RankedCustomers rc
LEFT JOIN 
    AddressSummary asum ON rc.c_customer_id IN (
        SELECT 
            c.c_customer_id 
        FROM 
            customer c 
        JOIN 
            customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE 
            ca.ca_state = rc.cd_gender
    )
LEFT JOIN 
    SalesSummary ss ON rc.c_customer_id IN (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk = rc.c_customer_sk
    )
WHERE 
    rc.rn <= 10
ORDER BY 
    rc.cd_gender, rc.rn;
