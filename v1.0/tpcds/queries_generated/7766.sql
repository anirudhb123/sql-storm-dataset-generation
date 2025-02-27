
WITH sales_summary AS (
    SELECT
        item.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_units_sold,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        item.i_current_price,
        rr.r_reason_desc
    FROM
        item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON item.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON item.i_item_sk = ss.ss_item_sk
    LEFT JOIN store_returns sr ON item.i_item_sk = sr.sr_item_sk
    LEFT JOIN reason rr ON sr.sr_reason_sk = rr.r_reason_sk
    WHERE
        (ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231 OR 
         cs.cs_sold_date_sk BETWEEN 20200101 AND 20201231 OR 
         ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231)
    GROUP BY
        item.i_item_id, item.i_current_price, rr.r_reason_desc
)
SELECT
    s.i_item_id,
    s.total_units_sold,
    s.total_sales,
    s.i_current_price,
    s.r_reason_desc,
    DENSE_RANK() OVER (PARTITION BY s.r_reason_desc ORDER BY s.total_sales DESC) AS sales_rank
FROM
    sales_summary s
WHERE
    s.total_units_sold > 100
ORDER BY
    s.r_reason_desc, sales_rank
LIMIT 50;
