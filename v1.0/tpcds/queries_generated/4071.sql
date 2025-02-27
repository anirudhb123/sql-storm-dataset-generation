
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating,
        addr.ca_state,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_income_band_sk, cd.cd_credit_rating, addr.ca_state
),
high_profit_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_income_band_sk,
        ci.cd_credit_rating,
        ci.ca_state,
        ci.total_returns,
        rs.total_profit
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.rank_profit = 1
        AND ci.total_returns > 0
)
SELECT 
    hpc.c_customer_sk,
    hpc.c_first_name || ' ' || hpc.c_last_name AS customer_name,
    hpc.cd_gender,
    hpc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hpc.total_returns,
    hpc.total_profit,
    CASE 
        WHEN hpc.cd_gender = 'F' THEN 'Female'
        WHEN hpc.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender_description
FROM 
    high_profit_customers hpc
JOIN 
    income_band ib ON hpc.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    hpc.ca_state IS NOT NULL
ORDER BY 
    hpc.total_profit DESC
FETCH FIRST 50 ROWS ONLY;
