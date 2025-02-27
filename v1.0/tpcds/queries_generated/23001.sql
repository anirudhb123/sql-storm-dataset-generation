
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
daily_average AS (
    SELECT 
        d.d_date_sk,
        AVG(ss.total_sales) AS avg_daily_sales
    FROM sales_summary ss
    JOIN date_dim d ON d.d_date_sk = ss.ws_sold_date_sk
    GROUP BY d.d_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.gender,
        ci.max_purchase_estimate,
        DENSE_RANK() OVER (ORDER BY ci.max_purchase_estimate DESC) AS rank
    FROM customer_info ci
    WHERE ci.max_purchase_estimate IS NOT NULL
    AND ci.max_purchase_estimate >= (SELECT AVG(max_purchase_estimate) FROM customer_info)
)
SELECT 
    w.w_warehouse_name,
    ds.d_date_id,
    tc.gender,
    tc.max_purchase_estimate,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales_for_day,
    da.avg_daily_sales,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Other Customer'
    END AS customer_category
FROM daily_average da
RIGHT JOIN sales_summary ss ON ss.ws_sold_date_sk = da.d_date_sk
JOIN warehouse w ON w.w_warehouse_sk = (SELECT MAX(inv.inv_warehouse_sk) FROM inventory inv WHERE inv.inv_item_sk = ss.ws_item_sk)
JOIN top_customers tc ON tc.c_customer_sk = ss.ws_bill_customer_sk
JOIN date_dim ds ON ds.d_date_sk = ss.ws_sold_date_sk
WHERE ds.d_year = 2023
GROUP BY w.w_warehouse_name, ds.d_date_id, tc.gender, tc.max_purchase_estimate, da.avg_daily_sales, tc.rank
HAVING AVG(total_sales_for_day) IS NOT NULL
ORDER BY total_sales_for_day DESC, w.w_warehouse_name, ds.d_date_id;
