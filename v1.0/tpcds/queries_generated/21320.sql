
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        ws.ws_item_sk
),
StoreSalesDetails AS (
    SELECT
        ss.ss_item_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        store_sales ss
    JOIN
        inventory inv ON ss.ss_item_sk = inv.inv_item_sk
    WHERE
        inv.inv_quantity_on_hand >= 0
    GROUP BY
        ss.ss_item_sk
),
FinalSales AS (
    SELECT
        rs.ws_item_sk,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(ss.store_transactions, 0) AS store_transactions,
        COALESCE(ss.total_profit, 0) AS total_profit,
        CASE
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN 'No Sales'
            ELSE 'Sales Recorded'
        END AS sales_status,
        CASE
            WHEN COALESCE(ss.total_profit, 0) >= 1000 THEN 'High Profit'
            WHEN COALESCE(ss.total_profit, 0) BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_band
    FROM
        RankedSales rs
    FULL OUTER JOIN
        StoreSalesDetails ss ON rs.ws_item_sk = ss.ss_item_sk
)
SELECT
    COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
    fs.total_quantity,
    fs.total_sales,
    fs.store_transactions,
    fs.total_profit,
    fs.sales_status,
    fs.profit_band,
    CASE
        WHEN fs.total_sales IS NULL THEN NULL
        ELSE ROUND(fs.total_sales / NULLIF(fs.total_quantity, 0), 2)
    END AS avg_sales_price_per_unit
FROM
    FinalSales fs
LEFT JOIN
    item i ON fs.ws_item_sk = i.i_item_sk
WHERE
    fs.total_profit IS NOT NULL
ORDER BY
    fs.total_profit DESC, fs.total_sales DESC;
