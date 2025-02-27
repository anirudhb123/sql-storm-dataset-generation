
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450100

    UNION ALL

    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sold_date_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2450000 AND 2450100
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        SalesCTE
),
CustomerReturn AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalSummary AS (
    SELECT 
        rs.ws_item_sk,
        COALESCE(SUM(rs.ws_quantity), 0) AS total_sold,
        COALESCE(cr.total_returned, 0) AS total_returns,
        (COALESCE(SUM(rs.ws_quantity), 0) - COALESCE(cr.total_returned, 0)) AS net_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturn cr ON rs.ws_item_sk = cr.sr_item_sk
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sold,
    f.total_returns,
    f.net_sales,
    CASE 
        WHEN f.net_sales IS NULL OR f.net_sales < 0 THEN 'Underperforming'
        WHEN f.net_sales BETWEEN 1 AND 100 THEN 'Average'
        ELSE 'High Performer'
    END AS performance_category
FROM 
    FinalSummary f
WHERE 
    f.total_sold > 5
ORDER BY 
    net_sales DESC
LIMIT 10;
