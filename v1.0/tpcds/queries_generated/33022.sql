
WITH RecursiveSalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk, 
        c_first_name,
        c_last_name,
        cd_income_band_sk,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c_first_name IS NOT NULL AND c_last_name IS NOT NULL 
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd_income_band_sk
    HAVING SUM(ws_net_paid) > 1000
),
SalesSummary AS (
    SELECT 
        inv.inv_date_sk,
        i.i_item_id,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
        COUNT(DISTINCT hs.i_item_sk) AS total_sales_count
    FROM inventory inv 
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = inv.inv_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = inv.inv_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = inv.inv_date_sk
    LEFT JOIN item i ON i.i_item_sk = cs.cs_item_sk OR i.i_item_sk = ss.ss_item_sk OR i.i_item_sk = ws.ws_item_sk
    LEFT JOIN RecursiveSalesCTE r ON r.ws_item_sk = i.i_item_sk
    LEFT JOIN HighValueCustomers hvc ON hvc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY inv.inv_date_sk, i.i_item_id
)
SELECT 
    ss.inv_date_sk,
    i.i_item_id,
    ss.total_catalog_sales,
    ss.total_store_sales,
    ss.total_web_sales,
    ss.total_sales_count,
    hd.hd_income_band_sk AS customer_income_band,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count
FROM SalesSummary ss
LEFT JOIN item i ON ss.i_item_id = i.i_item_id
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = (SELECT hd_demo_sk FROM household_demographics WHERE hd_income_band_sk IS NOT NULL LIMIT 1)
LEFT JOIN HighValueCustomers hvc ON hvc.total_spent > 500
WHERE ss.total_web_sales > 5000
GROUP BY ss.inv_date_sk, i.i_item_id, hd.hd_income_band_sk
ORDER BY ss.inv_date_sk DESC, ss.total_web_sales DESC
FETCH FIRST 100 ROWS ONLY;
