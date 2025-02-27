
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender
    FROM RankedCustomers c
    WHERE c.PurchaseRank <= 5
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS TotalOrders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.ca_city,
    fc.ca_state,
    fc.cd_gender,
    COALESCE(sd.TotalSales, 0) AS TotalSales,
    COALESCE(sd.TotalOrders, 0) AS TotalOrders
FROM FilteredCustomers fc
LEFT JOIN SalesData sd ON fc.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY TotalSales DESC;
