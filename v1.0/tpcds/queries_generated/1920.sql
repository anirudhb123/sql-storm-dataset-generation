
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2022 AND d_moy BETWEEN 1 AND 6
    )
    GROUP BY ws_item_sk
),
ReturnsData AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2022 AND d_moy BETWEEN 1 AND 6
    )
    GROUP BY wr_item_sk
),
ItemSummary AS (
    SELECT
        i_item_sk,
        i_product_name,
        COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(rd.total_return_quantity, 0) AS total_returns,
        COALESCE(rd.total_return_loss, 0) AS total_return_loss,
        COALESCE(sd.total_net_profit, 0) - COALESCE(rd.total_return_loss, 0) AS net_profit_after_returns
    FROM item
    LEFT JOIN SalesData sd ON i_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnsData rd ON i_item_sk = rd.wr_item_sk
)
SELECT
    is.i_item_sk,
    is.i_product_name,
    is.total_quantity_sold,
    is.total_net_profit,
    is.total_returns,
    is.total_return_loss,
    is.net_profit_after_returns
FROM ItemSummary is
WHERE is.net_profit_after_returns > 0
ORDER BY is.net_profit_after_returns DESC
LIMIT 10;
