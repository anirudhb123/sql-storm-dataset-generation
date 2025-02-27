
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY ws_item_sk
),
Top_Items AS (
    SELECT 
        s.store_sk,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_quantity) AS total_units_sold
    FROM store_sales s
    INNER JOIN store st ON s.ss_store_sk = st.s_store_sk
    LEFT JOIN store_returns sr ON s.ss_item_sk = sr.sr_item_sk AND s.ss_ticket_number = sr.sr_ticket_number
    WHERE sr.sr_item_sk IS NULL
    GROUP BY s_store_sk, s_store_name
),
Sales_Comparison AS (
    SELECT 
        t.store_sk,
        t.total_store_sales,
        COALESCE(i.total_sales, 0) AS total_web_sales
    FROM Top_Items t
    LEFT JOIN Sales_CTE i ON t.store_sk = i.ws_item_sk
)
SELECT 
    s.store_sk,
    s.s_store_name,
    MAX(s.total_store_sales) AS best_store_sales,
    MAX(s.total_web_sales) AS best_web_sales,
    CASE 
        WHEN MAX(s.total_store_sales) > MAX(s.total_web_sales) THEN 'Store'
        WHEN MAX(s.total_web_sales) > MAX(s.total_store_sales) THEN 'Web'
        ELSE 'Equal'
    END AS sales_leader
FROM Sales_Comparison s
GROUP BY s.store_sk, s.s_store_name
ORDER BY best_store_sales DESC, best_web_sales DESC;
