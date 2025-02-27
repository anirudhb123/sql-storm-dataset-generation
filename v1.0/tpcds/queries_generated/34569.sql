
WITH RECURSIVE RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 50
),
CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        COUNT(DISTINCT ws.order_number) AS total_sales, 
        SUM(ws.net_profit) AS total_revenue,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (SUM(ws.net_profit) / NULLIF(COALESCE(cr.total_returns, 0), 0)) AS revenue_per_return,
        (SUM(ws.net_profit) - COALESCE(cr.total_returns * AVG(ws.net_profit), 0)) AS net_profit_after_returns
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        CustomerReturns cr ON item.i_item_sk = cr.sr_item_sk
    GROUP BY 
        item.i_item_id
),
FinalReport AS (
    SELECT 
        s_summary.i_item_id,
        s_summary.total_sales,
        s_summary.total_revenue,
        s_summary.total_returns,
        s_summary.revenue_per_return,
        s_summary.net_profit_after_returns,
        COALESCE(rd.rank, 0) AS rank
    FROM 
        SalesSummary s_summary
    LEFT JOIN 
        RankedSales rd ON s_summary.i_item_id = rd.ws_item_sk
)
SELECT 
    f_report.i_item_id,
    f_report.total_sales,
    f_report.total_revenue,
    f_report.total_returns,
    f_report.revenue_per_return,
    f_report.net_profit_after_returns,
    f_report.rank
FROM 
    FinalReport f_report
WHERE 
    f_report.total_sales > 100
ORDER BY 
    f_report.total_revenue DESC;
