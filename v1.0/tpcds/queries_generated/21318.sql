
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_item_sk,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2022 AND d_month_seq BETWEEN 1 AND 12
        )
), 
ItemReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
HighVolumeSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_net_paid,
        COALESCE(ir.total_returns, 0) AS total_returns,
        COALESCE(ir.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales rs
    LEFT JOIN 
        ItemReturns ir ON rs.ws_item_sk = ir.cr_item_sk
    WHERE 
        rs.rn <= 5
),
FinalReport AS (
    SELECT 
        site.w_warehouse_name,
        COALESCE(hvs.ws_net_paid, 0) AS total_sales,
        hvs.total_returns,
        hvs.total_return_amount,
        (COALESCE(hvs.ws_net_paid, 0) - COALESCE(hvs.total_return_amount, 0)) AS net_revenue
    FROM 
        warehouse site
    LEFT JOIN 
        HighVolumeSales hvs ON site.w_warehouse_sk = hvs.web_site_sk
)
SELECT 
    *,
    CASE WHEN net_revenue > 0 THEN 'Profitable' ELSE 'Loss' END AS profitability,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales' 
        WHEN total_sales > 10000 THEN 'High Sales' 
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    FinalReport
WHERE 
    site.w_warehouse_name IS NOT NULL
ORDER BY 
    net_revenue DESC, total_returns DESC;
