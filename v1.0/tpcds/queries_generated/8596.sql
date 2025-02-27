
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2019 AND 2023
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_id, d.d_year
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS warehouse_sales
    FROM warehouse w 
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
),
gender_income AS (
    SELECT 
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender IN ('M', 'F')
    GROUP BY cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    ss.web_site_id,
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.average_profit,
    ws.warehouse_sales,
    gi.cd_gender,
    gi.ib_lower_bound,
    gi.ib_upper_bound,
    gi.customer_count
FROM sales_summary ss
JOIN warehouse_sales ws ON ss.web_site_id = ws.warehouse_sales
JOIN gender_income gi ON gi.customer_count > 0
ORDER BY ss.total_sales DESC, ss.d_year ASC;
