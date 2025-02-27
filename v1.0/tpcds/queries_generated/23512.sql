
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sold_date_sk DESC) AS SaleRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IS NOT NULL
), HighestSale AS (
    SELECT
        r.web_site_sk,
        MAX(r.web_sales_price) AS MaxSales
    FROM
        RankedSales r
    WHERE
        r.SaleRank <= 5
    GROUP BY
        r.web_site_sk
), CustomerSales AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS OrderCount,
        SUM(ws.ws_net_profit) AS TotalProfit,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS DistinctShipModes,
        COALESCE(MAX(wr.w_return_quantity), 0) AS TotalReturns
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY
        c.c_customer_sk
), CustomerAnalytics AS (
    SELECT
        cs.c_customer_sk,
        CASE
            WHEN cs.TotalProfit > 1000 THEN 'High Roller'
            WHEN cs.TotalProfit BETWEEN 500 AND 1000 THEN 'Mid Tier'
            ELSE 'Low Spender'
        END AS CustomerTier,
        MAX(cs.TotalReturns) AS MaxReturns,
        SUM(ha.MaxSales) AS TotalHighestSales
    FROM
        CustomerSales cs
    LEFT JOIN
        HighestSale ha ON ha.web_site_sk IN (SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_sk)
    GROUP BY
        cs.c_customer_sk
)
SELECT
    ca.c_first_name,
    ca.c_last_name,
    ca.c_email_address,
    ca.CustomerTier,
    ca.MaxReturns,
    ca.TotalHighestSales
FROM
    customer ca
JOIN
    CustomerAnalytics ca ON ca.c_customer_sk = ca.c_customer_sk
WHERE
    (ca.CustomerTier IS NOT NULL OR ca.CustomerTier IN ('High Roller', 'Mid Tier'))
    AND (ca.TotalHighestSales > 0 OR ca.MaxReturns IS NOT NULL)
ORDER BY
    ca.TotalHighestSales DESC, ca.MaxReturns ASC;
