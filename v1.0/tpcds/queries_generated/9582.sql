
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk AS DateSK,
        ws_item_sk AS ItemSK,
        SUM(ws_quantity) AS TotalQuantity,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS TotalOrders
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk AS CustomerID,
        cd.cd_gender AS Gender,
        cd.cd_marital_status AS MaritalStatus,
        cd.cd_credit_rating AS CreditRating,
        ca.ca_city AS City,
        ca.ca_state AS State,
        hd.hd_income_band_sk AS IncomeBand
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
AggregatedData AS (
    SELECT 
        sd.DateSK,
        cd.City,
        cd.State,
        cd.Gender,
        cd.MaritalStatus,
        cd.CreditRating,
        cb.ib_income_band_sk,
        SUM(sd.TotalSales) AS TotalSales,
        SUM(sd.TotalQuantity) AS TotalQuantity,
        COUNT(DISTINCT sd.TotalOrders) AS TotalOrders
    FROM 
        SalesData sd
    JOIN 
        CustomerData cd ON cd.CustomerID = sd.ItemSK
    GROUP BY 
        sd.DateSK, cd.City, cd.State, cd.Gender, cd.MaritalStatus, cd.CreditRating, cb.ib_income_band_sk
)
SELECT 
    a.DateSK,
    a.City,
    a.State,
    a.Gender,
    a.MaritalStatus,
    a.CreditRating,
    a.IncomeBand,
    a.TotalSales,
    a.TotalQuantity,
    a.TotalOrders
FROM 
    AggregatedData a
WHERE 
    a.TotalSales > 1000 
ORDER BY 
    a.DateSK, a.City;
