
WITH RankedReturns AS (
    SELECT 
        s.s_store_sk,
        sr_return_date_sk,
        sr_item_sk,
        sr_quantity,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY sr_return_date_sk DESC) AS rnk
    FROM 
        store s
    LEFT JOIN 
        store_returns sr ON s.s_store_sk = sr.s_store_sk
    WHERE 
        sr_return_date_sk IS NOT NULL
),
FilteredReturns AS (
    SELECT 
        s_store_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        RankedReturns
    WHERE 
        rnk <= 10
    GROUP BY 
        s_store_sk, sr_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CombinedData AS (
    SELECT 
        fr.s_store_sk,
        fr.sr_item_sk,
        COALESCE(fr.total_returned, 0) AS total_returned,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL
            ELSE COALESCE(fr.total_returned, 0) / COALESCE(sd.total_sales, 0)
        END AS return_rate
    FROM 
        FilteredReturns fr
    FULL OUTER JOIN 
        SalesData sd ON fr.sr_item_sk = sd.ws_item_sk
)
SELECT 
    w.w_warehouse_id,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    AVG(return_rate) AS avg_return_rate,
    STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' (', cd.cd_marital_status, ')'), ', ') AS demographics,
    SUM(CASE 
        WHEN return_rate > 0.1 THEN 1 
        ELSE 0 
    END) AS high_return_count
FROM 
    CombinedData cd
LEFT JOIN 
    warehouse w ON cd.s_store_sk = w.w_warehouse_sk
WHERE 
    w.w_country = 'USA' 
    AND (cd.return_rate IS NULL OR cd.return_rate < 0.5)
GROUP BY 
    w.w_warehouse_id
HAVING 
    COUNT(DISTINCT cd.s_store_sk) > 1
ORDER BY 
    unique_customers DESC
LIMIT 10;
