
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_ship_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_net_profit IS NOT NULL
    GROUP BY
        ws.ws_item_sk
),
MaxProfitItems AS (
    SELECT
        r.ws_item_sk,
        i.i_item_desc,
        r.total_quantity,
        r.total_profit
    FROM
        RankedSales r
    JOIN
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE
        r.rank_profit <= 10
),
StorePerformance AS (
    SELECT
        ss.ss_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ss.ss_store_sk
),
TopStores AS (
    SELECT
        sp.ss_store_sk,
        sp.total_sales,
        sp.total_store_profit,
        RANK() OVER (ORDER BY sp.total_store_profit DESC) AS store_rank
    FROM
        StorePerformance sp
)
SELECT
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_profit,
    ts.ss_store_sk,
    ts.total_sales,
    ts.total_store_profit
FROM
    MaxProfitItems tsi
JOIN
    TopStores ts ON tsi.total_profit > (SELECT AVG(total_profit) FROM MaxProfitItems)
LEFT JOIN
    customer c ON c.c_current_cdemo_sk IS NULL OR c.c_first_names NOT LIKE '.*@%'
WHERE
    c.c_birth_year IS NULL OR c.c_birth_year BETWEEN 1980 AND 1990
ORDER BY
    tsi.total_profit DESC, ts.total_store_profit DESC
LIMIT 100;
