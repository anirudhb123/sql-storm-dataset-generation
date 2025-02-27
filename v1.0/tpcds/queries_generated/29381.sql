
WITH AddressInfo AS (
    SELECT 
        ca.city AS City,
        ca.state AS State,
        COUNT(DISTINCT c.customer_sk) AS CustomerCount,
        AVG(cd.purchase_estimate) AS AvgPurchaseEstimate,
        SUM(
            CASE 
                WHEN cd.gender = 'F' THEN 1 
                ELSE 0 
            END
        ) AS FemaleCount,
        SUM(
            CASE 
                WHEN cd.gender = 'M' THEN 1 
                ELSE 0 
            END
        ) AS MaleCount
    FROM 
        customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
SalesInfo AS (
    SELECT 
        ws.web_site_id AS WebsiteID,
        COUNT(ws.order_number) AS TotalOrders,
        SUM(ws.net_profit) AS TotalProfit,
        SUM(ws.net_paid_inc_tax) AS TotalRevenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)
SELECT 
    a.City,
    a.State,
    a.CustomerCount,
    a.AvgPurchaseEstimate,
    a.FemaleCount,
    a.MaleCount,
    s.WebsiteID,
    s.TotalOrders,
    s.TotalProfit,
    s.TotalRevenue
FROM 
    AddressInfo a
JOIN 
    SalesInfo s ON a.CustomerCount > 0 
ORDER BY 
    a.State, a.City;
