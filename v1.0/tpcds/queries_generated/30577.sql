
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_name
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        web_name,
        total_profit
    FROM SalesCTE
    WHERE rank_profit <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_marital_status,
    ci.cd_gender,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    tws.web_name,
    tws.total_profit
FROM CustomerInfo ci
JOIN (
    SELECT 
        web_site_sk,
        web_name,
        total_profit
    FROM TopWebSites
) tws ON ci.hd_income_band_sk IS NOT NULL
WHERE (ci.ib_lower_bound BETWEEN 30000 AND 60000 OR ci.ib_upper_bound BETWEEN 30000 AND 60000)
  AND ci.hd_buy_potential IS NOT NULL
  AND ci.c_first_name IS NOT NULL
ORDER BY tws.total_profit DESC, ci.c_last_name ASC;
