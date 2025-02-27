
WITH RankSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) as total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) as sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales,
        ic.i_item_desc,
        ic.i_brand,
        COALESCE((SELECT AVG(ss_net_profit) FROM store_sales ss WHERE ss.ss_item_sk = rs.ws_item_sk), 0) AS avg_store_profit,
        COALESCE((SELECT AVG(ws_net_profit) FROM web_sales ws WHERE ws.ws_item_sk = rs.ws_item_sk), 0) AS avg_web_profit
    FROM
        RankSales rs
    JOIN
        item ic ON rs.ws_item_sk = ic.i_item_sk
    WHERE
        rs.sales_rank <= 5
)
SELECT
    ti.ws_item_sk,
    ti.i_item_desc,
    ti.i_brand,
    ti.total_sales,
    ROUND(ti.avg_store_profit, 2) as avg_store_profit,
    ROUND(ti.avg_web_profit, 2) as avg_web_profit,
    CASE
        WHEN ti.avg_store_profit > ti.avg_web_profit THEN 'Store Sales More Profitable'
        WHEN ti.avg_store_profit < ti.avg_web_profit THEN 'Web Sales More Profitable'
        ELSE 'Equal Profit'
    END AS profitability_comparison
FROM
    TopItems ti
LEFT JOIN
    store s ON s.s_store_sk IN (
        SELECT ss_store_sk FROM store_sales ss
        WHERE ss.ss_item_sk = ti.ws_item_sk
        GROUP BY ss_store_sk
    )
WHERE
    s.s_country = 'United States'
ORDER BY
    ti.total_sales DESC;
