
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM customer AS c
    JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_id
),
Promotions AS (
    SELECT 
        cs.c_customer_id,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        AVG(p.p_cost) AS avg_promo_cost
    FROM CustomerSales cs
    JOIN catalog_sales ct ON ct.cs_bill_customer_sk = cs.c_customer_id
    JOIN promotion p ON ct.cs_promo_sk = p.p_promo_sk
    GROUP BY cs.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS demographic_count
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    hd.ib_lower_bound,
    hd.ib_upper_bound,
    COALESCE(SUM(cs.total_sales), 0) AS total_sales,
    COALESCE(SUM(p.promo_count), 0) AS total_promotions,
    AVG(p.avg_promo_cost) AS avg_promotion_cost,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM CustomerDemographics cd
LEFT JOIN CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_id
LEFT JOIN Promotions p ON cs.c_customer_id = p.cs_customer_id
LEFT JOIN income_band hd ON cd.hd_income_band_sk = hd.ib_income_band_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    hd.ib_lower_bound, 
    hd.ib_upper_bound
ORDER BY total_sales DESC;
