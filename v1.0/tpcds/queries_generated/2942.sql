
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
), FilteredSales AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        MAX(ws.ws_ext_sales_price) AS max_sales_price
    FROM
        warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name
), FinalReport AS (
    SELECT
        f.w_warehouse_id,
        f.w_warehouse_name,
        f.total_net_paid,
        COALESCE(f.max_sales_price, 0) AS max_sales_price,
        COALESCE(r.ws_quantity, 0) AS rank_quantity
    FROM
        FilteredSales f
    LEFT JOIN RankedSales r ON f.w_warehouse_id = r.web_site_sk AND r.rank = 1
)
SELECT
    fw.w_warehouse_name,
    fw.total_net_paid,
    fw.max_sales_price,
    fw.rank_quantity
FROM
    FinalReport fw
WHERE
    fw.total_net_paid > 1000
ORDER BY
    fw.total_net_paid DESC
LIMIT 10;
