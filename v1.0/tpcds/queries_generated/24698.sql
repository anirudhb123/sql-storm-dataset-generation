
WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
high_value_customers AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        s.total_sales,
        s.total_orders
    FROM demographic_analysis d
    JOIN sales_summary s ON d.c_customer_sk = s.ws_bill_cdemo_sk
    WHERE s.total_sales > 1000
)
SELECT 
    h.cd_gender,
    h.cd_marital_status,
    h.total_sales,
    COALESCE(h.total_orders, 0) AS order_count,
    CASE 
        WHEN h.total_sales > 5000 THEN 'Platinum'
        WHEN h.total_sales BETWEEN 1000 AND 5000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier,
    RANK() OVER (ORDER BY h.total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM sales_summary WHERE total_orders > 1) AS avg_sales_above_one_order
FROM high_value_customers h
LEFT JOIN store s ON h.total_sales = s.s_store_sk
WHERE h.cd_marital_status IS NOT NULL
ORDER BY h.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
