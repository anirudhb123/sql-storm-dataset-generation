
WITH processed_customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        LOWER(c.c_email_address) AS normalized_email,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, 
             cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
             ca.ca_city, ca.ca_state, ca.ca_zip, 
             hd.hd_income_band_sk, hd.hd_buy_potential
),
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_net_profit DESC) AS profit_rank
    FROM processed_customer_data
)
SELECT 
    full_name,
    normalized_email,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_zip,
    hd_income_band_sk,
    hd_buy_potential,
    total_net_profit,
    profit_rank
FROM ranked_customers
WHERE profit_rank <= 5
ORDER BY hd_income_band_sk, profit_rank;
