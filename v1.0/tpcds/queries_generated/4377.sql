
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 5
),
SalesAndReturns AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales, 
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        ws.ws_item_sk
),
SalesPerformance AS (
    SELECT 
        sr.total_sales,
        sr.total_returns,
        COALESCE(sr.total_sales, 0) - COALESCE(sr.total_returns, 0) AS net_sales,
        CASE 
            WHEN COALESCE(sr.total_sales, 0) = 0 THEN 0 
            ELSE ROUND((COALESCE(sr.total_returns, 0) / COALESCE(sr.total_sales, 0)) * 100, 2) 
        END AS return_rate
    FROM 
        SalesAndReturns sr
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk, 
        tc.c_first_name, 
        tc.c_last_name,
        tc.cd_gender,
        COALESCE(sp.net_sales, 0) AS net_sales,
        sp.return_rate
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesPerformance sp ON tc.c_customer_sk = sp.ws_item_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.net_sales,
    CASE 
        WHEN fr.return_rate IS NULL THEN 'No Sales'
        ELSE CONCAT(fr.return_rate, '%')
    END AS return_rate_status
FROM 
    FinalReport fr
WHERE 
    fr.net_sales > 0
ORDER BY 
    fr.net_sales DESC
LIMIT 10;
