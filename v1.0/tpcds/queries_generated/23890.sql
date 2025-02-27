
WITH RECURSIVE customer_income AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower,
        COALESCE(ib.ib_upper_bound, 0) AS income_upper,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY hd.hd_income_band_sk) AS income_rank
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
average_sales AS (
    SELECT 
        is.ws_item_sk,
        is.total_quantity,
        is.total_sales,
        AVG(is.total_sales) OVER (PARTITION BY is.ws_item_sk) AS avg_sales
    FROM item_sales is
),
sales_ranked AS (
    SELECT 
        ais.ws_item_sk,
        ais.total_quantity,
        ais.total_sales,
        ais.avg_sales,
        RANK() OVER (ORDER BY ais.total_sales DESC) AS sales_rank
    FROM average_sales ais
    WHERE ais.total_sales > 100
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.income_lower,
    ci.income_upper,
    sr.ws_item_sk,
    sr.total_quantity,
    sr.total_sales,
    COALESCE(sr.avg_sales, 0) AS average_sales,
    CASE 
        WHEN sr.sales_rank < 5 THEN 'Top Selling'
        WHEN sr.sales_rank BETWEEN 5 AND 10 THEN 'Average Selling'
        ELSE 'Low Selling'
    END AS sales_category
FROM customer_income ci
FULL OUTER JOIN sales_ranked sr ON ci.c_customer_sk = sr.ws_item_sk
WHERE 
    (ci.income_lower < 50000 AND sr.total_sales IS NOT NULL)
    OR (ci.income_lower >= 50000 AND sr.total_sales IS NULL)
ORDER BY 
    ci.c_last_name,
    ci.c_first_name,
    sr.total_sales DESC;
