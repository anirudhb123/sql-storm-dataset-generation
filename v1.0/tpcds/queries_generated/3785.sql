
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_income_band_sk, 
        hd.hd_buy_potential
),
high_value_customers AS (
    SELECT 
        customer_summary.*,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_spent DESC) AS rank_within_band
    FROM customer_summary
    WHERE total_spent > 1000
)

SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.hd_income_band_sk,
    hvc.hd_buy_potential,
    hvc.total_spent,
    hvc.online_orders,
    hvc.store_orders
FROM high_value_customers hvc
WHERE hvc.rank_within_band <= 10
ORDER BY 
    hvc.hd_income_band_sk,
    hvc.total_spent DESC;

-- Additionally, checking for missing information
SELECT
    ca.ca_zip,
    COUNT(c.c_customer_sk) AS customer_count
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_zip IS NULL OR ca.ca_zip = ''
GROUP BY ca.ca_zip
HAVING COUNT(c.c_customer_sk) > 10;
