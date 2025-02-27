
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM RankedSales
    WHERE rn <= 5
    GROUP BY ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate,
        COALESCE(hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        w.ws_item_sk,
        SUM(w.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT w.ws_order_number) AS total_orders
    FROM web_sales w
    JOIN TopSellingItems t ON w.ws_item_sk = t.ws_item_sk
    GROUP BY w.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_credit_rating,
    c.cd_purchase_estimate,
    s.total_net_profit,
    s.total_orders,
    CASE 
        WHEN c.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status_label,
    (SELECT COUNT(*) 
     FROM customer d 
     WHERE d.c_current_hdemo_sk = c.c_current_hdemo_sk) AS total_customers_in_household
FROM CustomerInfo c
JOIN SalesData s ON c.c_customer_sk = s.ws_item_sk
WHERE c.cd_purchase_estimate > 1000
ORDER BY s.total_net_profit DESC, c.c_last_name ASC;
