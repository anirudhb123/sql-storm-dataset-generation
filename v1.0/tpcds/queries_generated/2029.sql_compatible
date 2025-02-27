
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS orders_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_moy = 10
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        cd.cd_age_group,
        cd.cd_marital_status,
        hd.hd_income_band_sk 
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), RankedSales AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_spent, 
        cs.orders_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM CustomerSales cs
)
SELECT 
    r.c_first_name, 
    r.c_last_name, 
    r.total_spent, 
    r.orders_count,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Has Income Band' 
        ELSE 'No Income Band' 
    END AS income_band_status
FROM RankedSales r
LEFT JOIN CustomerDemographics cd ON r.c_customer_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON cd.hd_income_band_sk = hd.hd_income_band_sk
WHERE r.sales_rank <= 10 AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY r.total_spent DESC;
