
WITH RankedSales AS (
    SELECT
        ws.s_old_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank,
        COALESCE(NULLIF(ws.ws_ext_sales_price, 0), NULL) AS adjusted_sales_price
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IS NOT NULL AND
        ws.ws_quantity > 0
),
DailySales AS (
    SELECT
        dd.d_date,
        SUM(CASE WHEN rs.rank = 1 THEN rs.ws_quantity ELSE 0 END) AS total_first_day_quantity,
        SUM(rs.ws_sales_price) AS total_sales,
        AVG(rs.adjusted_sales_price) AS avg_adjusted_price
    FROM
        date_dim dd
    LEFT JOIN RankedSales rs ON dd.d_date_sk = rs.s_old_date_sk
    GROUP BY
        dd.d_date
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_id,
        COUNT(ss.ticket_number) AS total_sales
    FROM 
        store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_market_id
)
SELECT
    di.d_date,
    si.s_store_name,
    si.s_city,
    si.s_state,
    si.total_sales AS store_sales,
    ds.total_first_day_quantity,
    ds.total_sales AS daily_sales,
    ds.avg_adjusted_price,
    CASE 
        WHEN ds.total_sales > (SELECT AVG(total_sales) FROM DailySales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance,
    CONCAT(si.s_store_name, ' in ', si.s_city, ' is ', 
           CASE WHEN si.total_sales > 0 THEN 'performing well' ELSE 'not performing well' END) AS performance_comment
FROM
    DailySales ds
JOIN StoreInfo si ON ds.d_date_sk = si.total_sales
WHERE
    ds.total_sales IS NOT NULL
ORDER BY
    ds.d_date, si.s_store_name;
