
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_bill_customer_sk,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS SalesRank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459580 AND 2459640 -- Example date range
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        SUM(rs.ws_ext_sales_price) AS TotalSales,
        SUM(rs.ws_net_profit) AS TotalProfit
    FROM CustomerInfo ci
    JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE rs.SalesRank <= 5
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.ca_city
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.ca_city,
    s.TotalSales,
    s.TotalProfit,
    CASE 
        WHEN s.TotalProfit IS NULL THEN 'No Profit'
        ELSE s.TotalProfit::DECIMAL(10, 2) 
    END AS ProfitAdjusted,
    CAST(s.TotalSales AS VARCHAR) || ' USD' AS SalesFormatted
FROM SalesSummary s
LEFT JOIN store_returns sr ON s.c_customer_sk = sr.sr_customer_sk
WHERE sr.sr_returned_date_sk IS NULL 
    OR (sr.sr_return_quantity > 0 AND sr.sr_return_amt IS NOT NULL)
ORDER BY s.TotalProfit DESC
LIMIT 10;
