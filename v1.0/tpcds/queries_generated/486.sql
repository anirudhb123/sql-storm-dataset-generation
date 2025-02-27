
WITH ranked_sales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS purchase_count,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_customer_sk
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COALESCE(hd_income_band_sk, 0) AS income_band,
        hd_buy_potential
    FROM customer_demographics
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
),
sales_info AS (
    SELECT 
        r.sales_rank,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.income_band,
        d.hd_buy_potential,
        r.total_sales,
        r.purchase_count,
        CASE 
            WHEN r.total_sales > 1000 THEN 'High Value'
            WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM ranked_sales r
    JOIN demographics d ON r.ss_customer_sk = d.cd_demo_sk
)
SELECT 
    si.cd_gender,
    si.income_band,
    SUM(si.total_sales) AS total_sales_by_demographic,
    AVG(si.purchase_count) AS avg_purchases,
    COUNT(*) AS customer_count
FROM sales_info si
WHERE si.customer_value_category = 'High Value'
GROUP BY si.cd_gender, si.income_band
ORDER BY total_sales_by_demographic DESC
LIMIT 10
UNION ALL
SELECT 
    'N/A' AS cd_gender,
    ib.ib_income_band_sk AS income_band,
    SUM(s.ws_net_paid) AS total_sales_by_demographic,
    AVG(s.ws_quantity) AS avg_purchases,
    COUNT(DISTINCT s.ws_bill_customer_sk) AS customer_count
FROM web_sales s
LEFT JOIN income_band ib ON s.ws_net_paid BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE ib.ib_income_band_sk IS NOT NULL
GROUP BY ib.ib_income_band_sk
ORDER BY total_sales_by_demographic DESC
LIMIT 10
