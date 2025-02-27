
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
    GROUP BY ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT o.ws_order_number) AS order_count,
        SUM(o.ws_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
IncomeBandStats AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_spent) AS avg_spent
    FROM CustomerStats cs
    JOIN household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(SUM(sd.total_quantity), 0) AS total_items_sold,
    COALESCE(SUM(sd.total_profit), 0) AS total_profit_generated,
    COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
    AVG(ib_stats.avg_spent) AS avg_customer_spent
FROM income_band ib
LEFT JOIN IncomeBandStats ib_stats ON ib.ib_income_band_sk = ib_stats.ib_income_band_sk
LEFT JOIN SalesData sd ON sd.total_orders > 10
LEFT JOIN CustomerStats cs ON cs.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY ib.ib_income_band_sk;
