
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        ws_list_price, 
        ws_quantity, 
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sold_date_sk DESC) AS rank_date,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS row_num
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk BETWEEN 2450022 AND 2451155
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
            ELSE CONCAT('Dependents: ', cd.cd_dep_count)
        END AS dependents_info
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        r.rank_date, 
        cd.c_customer_id, 
        SUM(r.ws_list_price * r.ws_quantity) AS total_sales,
        COUNT(*) AS transaction_count
    FROM 
        RankedSales r
    JOIN 
        CustomerDetails cd ON r.web_site_sk = cd.c_customer_id
    GROUP BY 
        r.rank_date, cd.c_customer_id
)
SELECT 
    sa.rank_date, 
    cd.c_customer_id, 
    sa.total_sales, 
    sa.transaction_count,
    CASE 
        WHEN sa.total_sales IS NULL OR sa.total_sales = 0 THEN 'No sales'
        WHEN sa.total_sales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    SalesAnalysis sa
JOIN 
    CustomerDetails cd ON sa.c_customer_id = cd.c_customer_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_returned_date_sk BETWEEN 2450022 AND 2451155 
        AND sr.sr_item_sk IN (
            SELECT ws.ws_item_sk 
            FROM web_sales ws 
            WHERE ws.ws_sold_date_sk = sa.rank_date 
        )
    )
    OR sa.transaction_count > 5
ORDER BY 
    sa.total_sales DESC, 
    sa.transaction_count DESC
LIMIT 100
UNION ALL
SELECT 
    NULL AS rank_date,
    'TOTAL' AS c_customer_id, 
    SUM(total_sales) AS total_sales, 
    COUNT(*) AS transaction_count,
    'Summary' AS customer_status
FROM 
    SalesAnalysis
WHERE 
    customer_status IS NOT NULL 
GROUP BY 
    customer_status
HAVING 
    total_sales > 0;
