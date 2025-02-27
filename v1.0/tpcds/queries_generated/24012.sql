
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS sale_count,
        CASE 
            WHEN SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) IS NULL THEN 'No Sales'
            ELSE 'Sales Available'
        END AS sales_status
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    ORDER BY 
        ws.ws_item_sk
), 
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(RS.price_rank, 0) AS highest_price_rank,
        COALESCE(RS.total_quantity, 0) AS total_sales,
        COALESCE(RS.sale_count, 0) AS number_of_sales,
        RS.sales_status
    FROM 
        item i
    LEFT JOIN RankedSales RS ON i.i_item_sk = RS.ws_item_sk
)
SELECT 
    ISNULL(cs_item_sk, wr_item_sk) AS identifier,
    i_desc.item_desc,
    CS.total_sales,
    WR.total_returns,
    ISNULL(CS.total_sales, 0) - ISNULL(WR.total_returns, 0) AS net_sales,
    CASE 
        WHEN (ISNULL(CS.total_sales, 0) > ISNULL(WR.total_returns, 0)) THEN 'Net Positive'
        WHEN (ISNULL(CS.total_sales, 0) < ISNULL(WR.total_returns, 0)) THEN 'Net Negative'
        ELSE 'Break Even'
    END AS net_status,
    (SELECT AVG(item_quantity) FROM (SELECT SUM(ws_quantity) AS item_quantity FROM web_sales GROUP BY ws_item_sk) AS avg_qty) AS overall_avg_sales
FROM 
    ItemSummary CS
FULL OUTER JOIN (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
) WR ON CS.i_item_sk = WR.wr_item_sk
WHERE 
    (CS.highest_price_rank IS NOT NULL AND CS.number_of_sales > 0) OR 
    (WR.total_returns IS NOT NULL AND WR.total_returns > 0)
ORDER BY 
    net_sales DESC, 
    i_desc.item_desc ASC;
