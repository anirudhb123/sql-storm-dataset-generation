
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451194 AND 2451554
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
total_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_ext_sales_price) AS total_sales
    FROM sales_data sd
    WHERE sd.rn = 1
    GROUP BY sd.ws_order_number
),
top_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ROW_NUMBER() OVER (ORDER BY SUM(ts.total_sales) DESC) AS customer_rank
    FROM customer_data cd
    JOIN total_sales ts ON cd.c_customer_sk = ts.ws_order_number
    GROUP BY cd.c_customer_sk, cd.c_first_name, cd.c_last_name
    HAVING SUM(ts.total_sales) > 1000
)
SELECT 
    tc.customer_rank,
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ts.total_sales) AS total_spent
FROM top_customers tc
JOIN customer_data cd ON tc.c_customer_sk = cd.c_customer_sk
LEFT JOIN income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
JOIN total_sales ts ON tc.ws_order_number = ts.ws_order_number
WHERE cd.cd_gender = 'F'
GROUP BY tc.customer_rank, tc.c_first_name, tc.c_last_name, cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_spent DESC
LIMIT 10;
