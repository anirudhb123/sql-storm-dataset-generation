
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        sr_store_sk, 
        SUM(sr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_store_sk
),
StoreSales AS (
    SELECT 
        ss_item_sk, 
        ss_store_sk, 
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_paid) AS total_sales_value
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ss_item_sk, ss_store_sk
),
JoinedData AS (
    SELECT 
        sr.item_sk,
        sr.total_return_quantity,
        sr.total_return_count,
        ss.total_sales_quantity,
        ss.total_sales_value,
        CASE 
            WHEN ss.total_sales_quantity IS NULL THEN 0
            ELSE (sr.total_return_quantity / ss.total_sales_quantity) * 100 
        END AS return_rate
    FROM 
        CustomerReturns sr
    LEFT JOIN 
        StoreSales ss ON sr.s_store_sk = ss.ss_store_sk AND sr.sr_item_sk = ss.ss_item_sk
)
SELECT 
    item_sk, 
    total_return_quantity, 
    total_return_count, 
    total_sales_quantity, 
    total_sales_value,
    return_rate
FROM 
    JoinedData
WHERE 
    return_rate IS NOT NULL 
    AND return_rate > 50
ORDER BY 
    return_rate DESC 
LIMIT 10;
