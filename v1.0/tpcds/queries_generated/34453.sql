
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_date, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_birth_year > 1980
    UNION ALL
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_date, c.c_current_cdemo_sk, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws_item_sk
),
StoreData AS (
    SELECT 
        s_store_sk,
        COUNT(ss_ticket_number) AS total_sales_count,
        SUM(ss_net_paid) AS total_revenue
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2022 AND d_moy IN (6, 7, 8)
    )
    GROUP BY s_store_sk
),
OuterJoinData AS (
    SELECT 
        c.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        sd.total_sales_count,
        sd.total_revenue,
        COALESCE(sd.total_sales, 0) AS online_sales
    FROM CustomerHierarchy ch
    LEFT JOIN StoreData sd ON ch.c_current_cdemo_sk = sd.s_store_sk
),
RankedSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    oj.c_first_name,
    oj.c_last_name,
    oj.total_sales_count,
    oj.total_revenue,
    rs.total_quantity,
    rs.total_sales,
    CASE 
        WHEN rs.total_sales > 5000 THEN 'High Seller'
        WHEN rs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM OuterJoinData oj
JOIN RankedSales rs ON oj.c_customer_sk = rs.ws_item_sk
WHERE oj.total_revenue IS NOT NULL
ORDER BY oj.total_revenue DESC, rs.total_sales DESC
LIMIT 100;
