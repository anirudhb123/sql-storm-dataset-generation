
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_id) AS GenderRank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        REPLACE(CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state), ' ', '-') AS ProcessedAddress
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'TX') 
        AND ca.ca_city LIKE 'San%'
),
SalesStatistics AS (
    SELECT 
        ws.ws_sold_date_sk,
        COUNT(ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_net_paid) AS TotalRevenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    fa.ProcessedAddress,
    ss.TotalOrders,
    ss.TotalRevenue
FROM 
    RankedCustomers rc
LEFT JOIN 
    FilteredAddresses fa ON rc.c_customer_id = fa.ca_address_id
LEFT JOIN 
    SalesStatistics ss ON fa.ca_zip = ss.ws_sold_date_sk
WHERE 
    rc.GenderRank <= 10;
