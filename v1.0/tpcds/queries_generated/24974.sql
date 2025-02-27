
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS Total_Net_Profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS Rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year IS NOT NULL AND 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S') AND
        (ws.ws_net_profit IS NOT NULL OR ws.ws_net_profit < 0) -- NULL logic with comparison
    GROUP BY
        ws.web_site_sk
),
MaxReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS Total_Returns,
        COUNT(DISTINCT cr.cr_order_number) AS Unique_Returned_Orders
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
    HAVING
        SUM(cr.cr_return_quantity) > 10
)
SELECT
    r.web_site_sk,
    r.Total_Net_Profit,
    COALESCE(m.Total_Returns, 0) AS Total_Returns,
    CASE
        WHEN r.Total_Net_Profit > 10000 THEN 'High Performer'
        WHEN r.Total_Net_Profit BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS Performance_Category,
    r.Rank
FROM
    RankedSales r
LEFT JOIN
    MaxReturns m ON r.web_site_sk = m.cr_item_sk
WHERE
    r.Rank <= 5   -- we only want the top 5 sites
ORDER BY
    r.Total_Net_Profit DESC
UNION
SELECT
    'N/A' AS web_site_sk,
    0 AS Total_Net_Profit,
    SUM(Total_Returns) AS Total_Returns,
    'Aggregate Returns' AS Performance_Category,
    NULL AS Rank
FROM
    MaxReturns
WHERE
    Total_Returns IS NOT NULL
HAVING
    COUNT(DISTINCT cr_order_number) > 5;  -- Unusual semantic conditional
```
