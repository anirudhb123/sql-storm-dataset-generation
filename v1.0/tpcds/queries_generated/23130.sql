
WITH RankedSales AS (
    SELECT 
        ws_web_site_sk,
        ws.sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    GROUP BY 
        ws_web_site_sk, ws.sold_date_sk
),
AggregatedDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate IS NOT NULL
    GROUP BY 
        cd_gender
),
ReturnsSummary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_tax) AS total_returned_tax 
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    wm.warehouse_id,
    wm.warehouse_name,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    ad.avg_purchase_estimate,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(r.total_returned_tax, 0) AS total_returned_tax
FROM 
    RankedSales rs
JOIN 
    warehouse wm ON wm.w_warehouse_sk = rs.ws_web_site_sk
LEFT JOIN 
    AggregatedDemographics ad ON ad.cd_gender = 'F'
LEFT JOIN 
    ReturnsSummary r ON r.sr_item_sk = rs.ws_sold_date_sk
WHERE 
    ad.customer_count > (SELECT COUNT(*) FROM customer) * 0.1
    AND wm.warehouse_sq_ft > (SELECT AVG(w_warehouse_sq_ft) FROM warehouse)
ORDER BY 
    total_sales DESC, sales_rank
LIMIT 10;
