
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS SalesRank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS TotalProfit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), 
TopWebsites AS (
    SELECT web_site_id
    FROM SalesCTE
    WHERE SalesRank <= 10
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.c_customer_sk) AS CustomerCount,
    SUM(cd.TotalProfit) AS OverallProfit
FROM CustomerDemographics cd
JOIN TopWebsites tw ON cd.c_customer_sk IN (
    SELECT 
        ws.ws_bill_customer_sk 
    FROM web_sales ws 
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_site_id = tw.web_site_id
)
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY OverallProfit DESC;
