
WITH SalesCTE AS (
    SELECT
        ws_bill_customer_sk AS CustomerID,
        SUM(ws_net_paid) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount,
        MAX(ws_ship_date_sk) AS LastPurchaseDate
    FROM
        web_sales
    WHERE
        ws_ship_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12
        )
    GROUP BY
        ws_bill_customer_sk
),
DemographicsCTE AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    d.City,
    d.Gender,
    d.MaritalStatus,
    d.IncomeBand,
    SUM(s.TotalSales) AS TotalSales,
    AVG(s.OrderCount) AS AvgOrders,
    COUNT(s.CustomerID) AS CustomerCount,
    COUNT(DISTINCT s.LastPurchaseDate) AS DistinctPurchaseDates
FROM
    SalesCTE s
JOIN
    DemographicsCTE d ON s.CustomerID = d.c_customer_sk
WHERE
    d.cd_purchase_estimate > 10000
GROUP BY
    d.City,
    d.Gender,
    d.MaritalStatus,
    d.IncomeBand
ORDER BY
    TotalSales DESC;
