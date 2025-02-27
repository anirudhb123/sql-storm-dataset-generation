
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_sales
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year >= 2022
    GROUP BY
        ws.web_site_sk, ws.ws_sold_date_sk
),
TopWebsites AS (
    SELECT
        web_site_sk,
        total_quantity,
        total_profit
    FROM
        RankedSales
    WHERE
        rank_sales <= 5
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate > 1000
),
ReturnStatistics AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
SaleReturnAnalysis AS (
    SELECT
        ws_ws.web_site_sk,
        ws_ws.ws_item_sk,
        SUM(ws_ws.ws_quantity) AS total_sold,
        COALESCE(rs.total_return_quantity, 0) AS total_return,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        (SUM(ws_ws.ws_quantity) - COALESCE(rs.total_return_quantity, 0)) AS net_sales
    FROM
        web_sales ws_ws
    LEFT JOIN
        ReturnStatistics rs ON ws_ws.ws_item_sk = rs.sr_item_sk
    GROUP BY
        ws_ws.web_site_sk, ws_ws.ws_item_sk
)
SELECT 
    tw.web_site_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sra.net_sales) AS total_net_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopWebsites tw
JOIN 
    SaleReturnAnalysis sra ON tw.web_site_sk = sra.web_site_sk
JOIN 
    customer c ON sra.ws_item_sk = c.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender IS NOT NULL
GROUP BY 
    tw.web_site_sk, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(sra.net_sales) > 5000
ORDER BY 
    total_net_sales DESC;
