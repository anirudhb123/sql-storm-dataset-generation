
WITH RECURSIVE SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IS NOT NULL
    GROUP BY
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk IS NOT NULL
    GROUP BY
        cs_sold_date_sk, cs_item_sk
),
SalesSummary AS (
    SELECT
        item.i_item_id,
        COALESCE(sd.ws_sold_date_sk, sd.cs_sold_date_sk) AS sold_date,
        SUM(sd.total_quantity) AS total_units_sold,
        SUM(sd.total_profit) AS total_profit
    FROM
        item AS item
    LEFT JOIN SalesData AS sd ON item.i_item_sk = sd.ws_item_sk OR item.i_item_sk = sd.cs_item_sk
    GROUP BY
        item.i_item_id,
        sold_date
)
SELECT
    s.item_id,
    s.sold_date,
    s.total_units_sold,
    s.total_profit,
    DENSE_RANK() OVER (PARTITION BY s.item_id ORDER BY s.total_profit DESC) AS profit_rank
FROM
    SalesSummary AS s
WHERE
    s.total_units_sold > 100
    AND s.total_profit IS NOT NULL
ORDER BY
    s.total_profit DESC
LIMIT 10;
