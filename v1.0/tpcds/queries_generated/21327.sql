
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
HighProfitItems AS (
    SELECT
        ws_item_sk,
        COUNT(*) AS sales_count,
        SUM(ws_net_profit) AS total_profit
    FROM RankedSales
    WHERE rank_profit = 1
    GROUP BY ws_item_sk
),
ItemDetails AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM item
    WHERE i_rec_end_date IS NULL
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_returned_customer_sk) AS unique_returners
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT
    id.i_item_sk,
    id.i_item_desc,
    COALESCE(sp.sales_count, 0) AS sales_count,
    COALESCE(sp.total_profit, 0) AS total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.unique_returners, 0) AS unique_returners,
    (CASE
        WHEN COALESCE(sp.total_profit, 0) > 1000 THEN 'High Profit'
        WHEN COALESCE(sp.total_profit, 0) BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END) AS profit_category,
    CONCAT(id.i_item_desc, ' - ', id.i_brand) AS full_item_description
FROM ItemDetails id
LEFT JOIN HighProfitItems sp ON id.i_item_sk = sp.ws_item_sk
LEFT JOIN CustomerReturns cr ON id.i_item_sk = cr.wr_item_sk
ORDER BY profit_category DESC, total_profit DESC, sales_count DESC
LIMIT 100;
