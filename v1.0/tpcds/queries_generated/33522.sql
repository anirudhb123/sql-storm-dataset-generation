
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_item_sk
),
FilteredSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (CASE 
            WHEN COALESCE(r.total_returns, 0) = 0 THEN s.total_sales
            ELSE s.total_sales - r.total_returns 
        END) AS net_sales
    FROM 
        SalesCTE s
    LEFT JOIN 
        CustomerReturns r ON s.ws_item_sk = r.wr_item_sk
    WHERE 
        s.rn = 1
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        (CASE 
            WHEN cd_purchase_estimate > 5000 THEN 'High'
            WHEN cd_purchase_estimate BETWEEN 3000 AND 5000 THEN 'Medium'
            ELSE 'Low' 
        END) AS income_band
    FROM 
        customer_demographics
),
SalesAnalysis AS (
    SELECT 
        fs.ws_item_sk,
        fs.total_sales,
        fs.total_returns,
        fs.net_sales,
        cd.income_band
    FROM 
        FilteredSales fs
    JOIN 
        CustomerDemographics cd ON fs.ws_item_sk BETWEEN cd.cd_demo_sk AND cd.cd_demo_sk + 1000
)
SELECT 
    sa.ws_item_sk,
    sa.total_sales,
    sa.total_returns,
    sa.net_sales,
    sa.income_band,
    RANK() OVER (PARTITION BY sa.income_band ORDER BY sa.net_sales DESC) AS sales_rank
FROM 
    SalesAnalysis sa
WHERE 
    (sa.total_sales > 100 OR sa.total_returns > 0)
ORDER BY 
    sa.income_band, sales_rank;
