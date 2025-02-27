
WITH RECURSIVE inventory_trends AS (
    SELECT 
        i.inv_item_sk,
        i.inv_date_sk,
        CAST(i.inv_quantity_on_hand AS INTEGER) AS quantity_change,
        ROW_NUMBER() OVER (PARTITION BY i.inv_item_sk ORDER BY i.inv_date_sk) AS rn
    FROM inventory i
    WHERE i.inv_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d)
    UNION ALL
    SELECT 
        it.inv_item_sk,
        it.inv_date_sk,
        CAST((it.inv_quantity_on_hand - it_prev.inv_quantity_on_hand) AS INTEGER) AS quantity_change,
        rn + 1
    FROM inventory_trends it
    JOIN inventory it_prev ON it.inv_item_sk = it_prev.inv_item_sk AND it.inv_date_sk = it_prev.inv_date_sk + 1
),
customer_segment AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        d.d_year,
        (SELECT COUNT(DISTINCT ws.ws_order_number) 
         FROM web_sales ws 
         WHERE ws.ws_ship_date_sk = d.d_date_sk) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_year
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.ib_income_band_sk,
    SUM(cs.total_sales) AS overall_sales,
    ss.total_orders,
    ss.total_revenue,
    ss.avg_sales_price,
    COALESCE(i_trends.quantity_change, 0) AS trend_change
FROM customer_segment cs
JOIN sales_summary ss ON 1=1
LEFT JOIN (
    SELECT 
        inv_item_sk, 
        SUM(quantity_change) AS quantity_change
    FROM inventory_trends
    GROUP BY inv_item_sk
) AS i_trends ON cs.ib_income_band_sk IS NULL
GROUP BY cs.cd_gender, cs.cd_marital_status, cs.ib_income_band_sk, ss.total_orders, ss.total_revenue, ss.avg_sales_price
ORDER BY cs.cd_gender, overall_sales DESC;
