
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_sales_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 90 
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss_store_sk
),
StoreStats AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_by_web_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_by_store_sales
    FROM store s
    LEFT JOIN catalog_sales cs ON s.s_store_sk = cs.cs_ship_address_sk
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    LEFT JOIN RankedSales rs ON s.s_store_sk = rs.ss_store_sk
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
)
SELECT 
    sts.s_store_id,
    sts.s_store_name,
    sts.s_city,
    sts.s_state,
    sts.total_catalog_sales,
    rs.total_sales,
    rs.total_sales_transactions,
    CASE
        WHEN sts.rank_by_web_sales <= 10 THEN 'Top 10 Web Sales'
        ELSE 'Not Top 10 Web Sales'
    END AS web_sales_status,
    CASE
        WHEN sts.rank_by_store_sales <= 10 THEN 'Top 10 Store Sales'
        ELSE 'Not Top 10 Store Sales'
    END AS store_sales_status
FROM StoreStats sts
JOIN RankedSales rs ON sts.s_store_sk = rs.ss_store_sk
WHERE rs.total_sales IS NOT NULL
ORDER BY total_sales DESC
LIMIT 20;
