
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS gender_rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
ItemStatistics AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
SalesAnalysis AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_catalog_sales
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_dow IN (1, 7)) 
    GROUP BY 
        cs.cs_item_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        COUNT(DISTINCT rr.sr_item_sk) AS distinct_store_returns,
        COALESCE(SUM(is.total_sold), 0) AS total_items_sold,
        COALESCE(SUM(sas.total_catalog_sales), 0) AS total_catalog_sales,
        COALESCE(SUM(CASE WHEN rr.rn = 1 THEN rr.sr_return_quantity END), 0) AS highest_return_quantity
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        RankedReturns rr ON cd.c_customer_id = rr.sr_returning_customer_sk
    LEFT JOIN 
        ItemStatistics is ON rr.sr_item_sk = is.i_item_sk
    LEFT JOIN 
        SalesAnalysis sas ON is.i_item_sk = sas.cs_item_sk
    GROUP BY 
        cd.c_customer_id, cd.c_first_name, cd.c_last_name
)
SELECT 
    *,
    CASE 
        WHEN total_items_sold > 100 THEN 'High Volume'
        WHEN total_items_sold BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END AS sales_category,
    CASE 
        WHEN highest_return_quantity IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM 
    FinalReport
WHERE 
    total_catalog_sales > 0
ORDER BY 
    total_items_sold DESC, c_first_name ASC;
