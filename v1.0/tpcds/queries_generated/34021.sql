
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    UNION ALL
    SELECT 
        ss.ss_item_sk,
        COALESCE(SUM(ss.ss_quantity), 0) + cte.total_quantity,
        COALESCE(SUM(ss.ss_net_profit), 0) + cte.total_sales,
        cte.level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesCTE cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE 
        cte.level < 5
    GROUP BY 
        ss.ss_item_sk, cte.total_quantity, cte.total_sales
), 
ReturnSummary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
SalesAll AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COALESCE(rs.return_count, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY COALESCE(SUM(ss.ss_net_profit), 0) DESC) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        ReturnSummary rs ON i.i_item_sk = rs.sr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, rs.return_count, rs.total_return_value
)
SELECT 
    sa.i_item_id,
    sa.total_web_sales,
    sa.total_catalog_sales,
    sa.total_store_sales,
    sa.total_returns,
    sa.total_return_value,
    CASE
        WHEN sa.total_returns > 0 THEN 'High'
        ELSE 'Low'
    END AS return_risk,
    RANK() OVER (ORDER BY sa.total_web_sales + sa.total_catalog_sales + sa.total_store_sales DESC) AS overall_sales_rank
FROM 
    SalesAll sa
WHERE 
    (sa.total_web_sales > 0 OR sa.total_catalog_sales > 0 OR sa.total_store_sales > 0)
    AND sa.total_sales_rank <= 10
ORDER BY 
    overall_sales_rank;
