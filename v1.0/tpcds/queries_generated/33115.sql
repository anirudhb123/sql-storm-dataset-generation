
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound 
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound 
    FROM income_band ib
    INNER JOIN income_ranges ir ON ib.ib_lower_bound > ir.ib_upper_bound
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating,
        COALESCE(hd.hd_buy_potential, 'Low') AS buy_potential,
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk 
         AND ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                     FROM date_dim d 
                                     WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1)) AS purchase_count_last_year,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, hd.hd_buy_potential
),
filtered_customers AS (
    SELECT *, 
    NTILE(4) OVER (ORDER BY web_order_count DESC) AS income_quartile
    FROM customer_data
    WHERE 
        purchase_count_last_year > 0 
        AND credit_rating IN ('Good', 'Excellent') 
        AND (buy_potential = 'High' OR buy_potential = 'Medium')
),
ranked_customers AS (
    SELECT *,
    DENSE_RANK() OVER (PARTITION BY income_quartile ORDER BY web_order_count DESC) AS customer_rank
    FROM filtered_customers
)
SELECT 
    fc.c_customer_sk, 
    fc.c_first_name, 
    fc.c_last_name, 
    fc.credit_rating, 
    fc.buy_potential,
    ir.ib_upper_bound, 
    COUNT(ss.ss_ticket_number) AS store_purchase_count
FROM ranked_customers fc
LEFT JOIN store_sales ss ON fc.c_customer_sk = ss.ss_customer_sk
LEFT JOIN income_ranges ir ON ir.ib_income_band_sk = fc.income_quartile
WHERE fc.customer_rank <= 5
GROUP BY fc.c_customer_sk, fc.c_first_name, fc.c_last_name, fc.credit_rating, fc.buy_potential, ir.ib_upper_bound
ORDER BY fc.income_quartile, store_purchase_count DESC;
