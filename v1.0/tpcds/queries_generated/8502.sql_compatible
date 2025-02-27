
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, hd.hd_income_band_sk, hd.hd_buy_potential
), frequent_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_orders,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS ranking
    FROM customer_data AS c
    WHERE c.total_orders > 5 AND c.total_spent > 1000
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.total_orders,
    fc.total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM frequent_customers AS fc
JOIN customer_demographics AS cd ON fc.c_customer_sk = cd.cd_demo_sk
JOIN income_band AS ib ON cd.cd_credit_rating = ib.ib_income_band_sk
WHERE fc.ranking <= 100
ORDER BY fc.total_spent DESC;
