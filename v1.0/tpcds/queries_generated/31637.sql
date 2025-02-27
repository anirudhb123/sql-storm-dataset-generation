
WITH RECURSIVE SalesCTE AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_profit) AS total_profit,
           1 AS level
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_profit) > 500
    UNION ALL
    SELECT ws.bill_customer_sk,
           SUM(ws.ws_net_profit) + s.total_profit,
           level + 1
    FROM web_sales ws
    JOIN SalesCTE s ON ws.ws_bill_customer_sk = s.customer_sk
    WHERE ws.ws_sold_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_bill_customer_sk
    HAVING SUM(ws.ws_net_profit) > 500
),
StoreSales AS (
    SELECT ss_store_sk, 
           SUM(ss_net_sales) AS total_store_sales
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq = 12)
    GROUP BY ss_store_sk
),
IncomeBands AS (
    SELECT hd.hd_income_band_sk,
           COUNT(c.c_customer_sk) AS customer_count,
           SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM household_demographics hd
    LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY hd.hd_income_band_sk
),
FinalReport AS (
    SELECT a.ca_city,
           s.total_store_sales,
           (SELECT COUNT(DISTINCT customer_sk) FROM SalesCTE WHERE level = 2) AS repeat_customers,
           ib.customer_count,
           ib.total_purchase_estimate
    FROM customer_address a
    LEFT JOIN StoreSales s ON a.ca_address_sk = s.ss_store_sk
    LEFT JOIN IncomeBands ib ON ib.hd_income_band_sk = (SELECT MAX(hd.hd_income_band_sk) FROM household_demographics hd)
)
SELECT DISTINCT fr.ca_city, 
                fr.total_store_sales,
                fr.repeat_customers,
                fr.customer_count,
                fr.total_purchase_estimate,
                CASE 
                    WHEN fr.total_store_sales IS NULL THEN 'No sales'
                    ELSE CONCAT('Sales: ', fr.total_store_sales)
                END AS sales_message
FROM FinalReport fr
WHERE fr.total_store_sales IS NOT NULL
ORDER BY fr.total_store_sales DESC;
