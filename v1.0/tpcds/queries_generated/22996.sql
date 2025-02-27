
WITH InventoryDetails AS (
    SELECT 
        inv.warehouse_sk,
        inv.item_sk,
        inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv.item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM 
        inventory inv
),
RecentReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        SUM(sr.return_quantity) AS total_returned,
        COUNT(DISTINCT sr.ticket_number) AS distinct_tickets
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity IS NOT NULL
    GROUP BY 
        sr.returned_date_sk, sr.return_time_sk, sr.item_sk, sr.customer_sk
),
Summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.total_returned) AS total_returned,
        COUNT(DISTINCT sr.customer_sk) AS customer_count,
        AVG(ic.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM 
        RecentReturns sr
    JOIN 
        customer_demographics cd ON sr.customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        InventoryDetails ic ON sr.item_sk = ic.item_sk AND ic.rn = 1
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
TopReturns AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        total_returned,
        customer_count,
        ROW_NUMBER() OVER (ORDER BY total_returned DESC) as rank
    FROM 
        Summary
)
SELECT 
    tr.cd_gender,
    tr.cd_marital_status,
    tr.total_returned,
    tr.customer_count,
    CASE 
        WHEN tr.total_returned IS NULL THEN 'No Returns'
        ELSE 'Returns'
    END AS return_status,
    COALESCE(tr.avg_quantity_on_hand, 0) AS avg_quantity_hand
FROM 
    TopReturns tr
WHERE 
    (tr.rank <= 5 AND tr.customer_count > 10) 
    OR (tr.cd_gender = 'F' AND tr.total_returned > 100)
UNION
SELECT 
    'Total' AS cd_gender,
    'N/A' AS cd_marital_status,
    SUM(total_returned),
    COUNT(DISTINCT customer_count),
    'Summary' AS return_status,
    AVG(avg_quantity_on_hand) 
FROM 
    Summary
HAVING 
    SUM(total_returned) > 500
ORDER BY 
    cd_gender, return_status DESC;
