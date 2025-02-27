
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
top_items AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        ss.total_sales,
        ss.order_count
    FROM sales_cte ss
    INNER JOIN item si ON ss.ws_item_sk = si.i_item_sk
    WHERE ss.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        (hd.hd_income_band_sk IS NOT NULL OR hd.hd_income_band_sk IS NULL)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_city, cd.cd_gender, hd.hd_income_band_sk
),
ranked_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.d_city,
        ci.cd_gender,
        ci.hd_income_band_sk,
        ci.total_orders,
        RANK() OVER (ORDER BY ci.total_orders DESC) AS customer_rank
    FROM customer_info ci
)
SELECT 
    tc.i_item_id,
    tc.i_item_desc,
    rc.c_first_name,
    rc.c_last_name,
    rc.d_city,
    rc.cd_gender,
    rc.total_orders,
    CASE 
        WHEN rc.hd_income_band_sk IS NOT NULL THEN 'Has Income Band'
        ELSE 'No Income Band'
    END AS income_band_status
FROM top_items tc
FULL OUTER JOIN ranked_customers rc ON tc.ws_item_sk = rc.c_customer_sk
WHERE rc.customer_rank <= 50 OR tc.total_sales > 1000
ORDER BY tc.total_sales DESC, rc.total_orders DESC;
