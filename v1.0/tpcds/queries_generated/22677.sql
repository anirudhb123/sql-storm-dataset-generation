
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, ca_country
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_zip, a.ca_country
    FROM customer_address a
    JOIN AddressCTE cte ON a.ca_state = cte.ca_state AND a.ca_zip LIKE CONCAT(cte.ca_zip, '%')
    WHERE a.ca_country IS NOT NULL
),
IncomeBandStats AS (
    SELECT hd.hd_income_band_sk, 
           COUNT(*) AS total_customers,
           SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM household_demographics hd
    LEFT JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk 
    GROUP BY hd.hd_income_band_sk
),
SalesData AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit,
           RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) as profit_rank
    FROM web_sales ws
    JOIN Item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50
    GROUP BY ws.ws_item_sk
)
SELECT 
    da.ca_city,
    da.ca_state,
    ib.ib_income_band_sk,
    ibs.total_customers,
    ibs.male_count,
    ibs.avg_purchase_estimate,
    sd.total_quantity,
    sd.total_net_profit
FROM AddressCTE da
LEFT JOIN income_band ib ON da.ca_city = ib.ib_income_band_sk
LEFT JOIN IncomeBandStats ibs ON ib.ib_income_band_sk = ibs.hd_income_band_sk
LEFT JOIN SalesData sd ON da.ca_address_sk = sd.ws_item_sk
WHERE da.ca_state IN ('NY', 'CA') 
AND (ib.ib_lower_bound <= ibs.total_customers OR ib.ib_upper_bound > 0)
AND sd.total_net_profit IS NOT NULL
ORDER BY da.ca_city, ib.ib_income_band_sk DESC, sd.total_net_profit DESC
FETCH FIRST 100 ROWS ONLY;
