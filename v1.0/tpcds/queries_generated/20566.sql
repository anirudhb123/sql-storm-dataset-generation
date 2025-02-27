
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(CONVERT(varchar, cd.cd_marital_status), 'N/A') AS marital_status,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING SUM(ss.ss_ext_sales_price) IS NOT NULL OR cd.cd_gender IS NOT NULL
    ORDER BY total_sales DESC
),
top_customers AS (
    SELECT TOP 10 *
    FROM customer_stats
    WHERE sales_rank <= 10
),
promotion_sales AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
),
sales_analysis AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        ts.total_sales,
        ps.promo_sales,
        CASE 
            WHEN ts.total_sales > ps.promo_sales THEN 'Higher Sales'
            ELSE 'Lower or Equal Sales'
        END AS sales_comparison
    FROM top_customers tc
    JOIN customer_stats ts ON tc.c_customer_sk = ts.c_customer_sk
    LEFT JOIN promotion_sales ps ON ps.promo_sales IS NOT NULL
),
final_report AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_comparison ORDER BY total_sales DESC) AS rn
    FROM sales_analysis
    WHERE sales_comparison IS NOT NULL
)
SELECT *
FROM final_report
WHERE rn <= 5
UNION ALL
SELECT 
    'Total Sales Summary' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_sales) AS total_sales,
    SUM(promo_sales) AS promo_sales,
    NULL AS sales_comparison
FROM sales_analysis
GROUP BY sales_comparison
HAVING SUM(total_sales) IS NOT NULL
ORDER BY total_sales DESC;
