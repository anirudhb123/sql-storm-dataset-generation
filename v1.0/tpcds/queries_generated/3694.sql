
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
high_profit_customers AS (
    SELECT
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.hd_buy_potential,
        rs.total_net_profit
    FROM 
        customer_info ci
    JOIN 
        store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    JOIN 
        ranked_sales rs ON ss.ss_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_net_profit > 100)
    WHERE 
        rs.profit_rank = 1
)
SELECT
    hpc.customer_name,
    hpc.cd_gender,
    hpc.cd_marital_status,
    hpc.hd_buy_potential,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit_generated
FROM
    high_profit_customers hpc
LEFT JOIN 
    store_sales ss ON hpc.customer_name = CONCAT(c.c_first_name, ' ', c.c_last_name)
GROUP BY
    hpc.customer_name, hpc.cd_gender, hpc.cd_marital_status, hpc.hd_buy_potential
HAVING 
    total_profit_generated > 5000
ORDER BY 
    total_profit_generated DESC;
