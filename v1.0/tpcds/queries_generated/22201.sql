
WITH RECURSIVE customer_tree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT ct.c_customer_sk, ct.c_first_name, ct.c_last_name, ct.c_current_cdemo_sk, ct.level + 1
    FROM customer_tree ct
    JOIN customer c ON ct.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ct.level < 5
),
buyer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        COALESCE(cd_dep_count, 0) AS dep_count,
        CASE 
            WHEN cd_dep_employed_count IS NULL THEN 'Unknown'
            WHEN cd_dep_employed_count > 0 THEN 'Employed'
            ELSE 'Unemployed'
        END AS employment_status
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
aggregated_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS average_profit,
        COUNT(DISTINCT ss_customer_sk) AS unique_buyers
    FROM store_sales
    WHERE ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
),
returns_summary AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_store_sk
),
final_report AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        br.buyer_risk_level
    FROM customer_tree c
    LEFT JOIN buyer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN aggregated_sales ss ON ss.ss_store_sk = c.c_current_addr_sk
    LEFT JOIN returns_summary rs ON rs.sr_store_sk = c.c_current_addr_sk
    LEFT JOIN (
        SELECT 
            SUM(total_sales) OVER () AS grand_total_sales,
            CASE 
                WHEN SUM(total_sales) OVER () > 1000000 THEN 'High'
                WHEN SUM(total_sales) OVER () BETWEEN 500000 AND 1000000 THEN 'Medium'
                ELSE 'Low'
            END AS buyer_risk_level
        FROM aggregated_sales
    ) br ON 1=1
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returns,
    f.buyer_risk_level,
    DENSE_RANK() OVER (ORDER BY f.total_sales DESC) AS sales_rank,
    CASE 
        WHEN f.total_sales IS NULL THEN 'Not a Buyer'
        ELSE 'Buyer'
    END AS buyer_status,
    STRING_AGG(DISTINCT CONCAT(f.c_first_name, ' ', f.c_last_name) ORDER BY f.c_last_name) OVER () AS all_buyers
FROM final_report f
WHERE f.total_sales > (SELECT AVG(total_sales) FROM aggregated_sales) 
ORDER BY f.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
