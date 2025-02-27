
WITH RankedSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sales_price > 0
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_item_sk
),
FilteredSales AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.ws_item_sk,
        r.total_quantity,
        r.total_profit
    FROM
        RankedSales r
    WHERE
        r.rank_profit <= 5
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT fs.ws_item_sk) AS item_count,
        AVG(fs.total_profit) AS avg_profit_per_item
    FROM
        customer c
    JOIN
        FilteredSales fs ON c.c_customer_sk = fs.c_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        AVG(fs.total_profit) > (SELECT AVG(total_profit) FROM RankedSales)
),
NullCases AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COALESCE(SUM(CASE WHEN ws.ws_item_sk IS NULL THEN 0 ELSE ws.ws_sales_price END), 0) AS total_sales,
        COALESCE(MAX(NULLIF(ws.ws_net_profit, 0)), 'No Profit') AS max_profit
    FROM
        warehouse w
    LEFT JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.item_count,
    hvc.avg_profit_per_item,
    nc.w_warehouse_name,
    nc.total_sales,
    nc.max_profit
FROM
    HighValueCustomers hvc
CROSS JOIN
    NullCases nc
WHERE
    hvc.item_count > 3
ORDER BY
    hvc.avg_profit_per_item DESC,
    nc.total_sales DESC;
