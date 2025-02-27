
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk, i.i_item_desc
),
ReturnStats AS (
    SELECT 
        cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
SalesAndReturns AS (
    SELECT 
        tsi.ws_item_sk,
        tsi.i_item_desc,
        tsi.total_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        TopSellingItems tsi
    LEFT OUTER JOIN 
        ReturnStats rs ON tsi.ws_item_sk = rs.cr_item_sk
)
SELECT 
    s.store_name,
    sa.ws_sold_date_sk,
    COALESCE(SUM(sar.total_net_profit), 0) AS total_net_profit,
    SUM(sar.total_returns) AS total_returns,
    SUM(sar.total_return_amount) AS total_return_amount
FROM 
    store s
LEFT JOIN 
    web_sales sa ON s.s_store_sk = sa.ws_ship_addr_sk
LEFT JOIN 
    SalesAndReturns sar ON sa.ws_item_sk = sar.ws_item_sk
GROUP BY 
    s.store_name, sa.ws_sold_date_sk
HAVING 
    SUM(sar.total_net_profit) > 1000
ORDER BY 
    s.store_name, sa.ws_sold_date_sk DESC;
