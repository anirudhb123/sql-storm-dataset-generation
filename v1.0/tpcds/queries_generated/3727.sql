
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        c.c_gender AS customer_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year >= 2020
    GROUP BY d.d_year, c.c_gender
), high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        cd.cd_credit_rating,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_gender, cd.cd_credit_rating
    HAVING SUM(ws.ws_ext_sales_price) > 10000
), inventory_status AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    GROUP BY i.i_item_sk, i.i_item_id, i.i_current_price
), orders_with_reasons AS (
    SELECT
        ws.ws_order_number,
        cr.cr_reason_sk,
        r.r_reason_desc,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    JOIN web_sales ws ON cr.cr_order_number = ws.ws_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY ws.ws_order_number, cr.cr_reason_sk, r.r_reason_desc
)
SELECT 
    ss.sales_year,
    ss.customer_gender,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    COALESCE(hvc.total_spent, 0) AS high_value_total,
    iv.total_inventory,
    COALESCE(rr.total_returns, 0) AS total_returns,
    rr.r_reason_desc
FROM sales_summary ss
LEFT JOIN high_value_customers hvc ON ss.customer_gender = hvc.c_gender
LEFT JOIN inventory_status iv ON hvc.c_customer_sk = iv.i_item_sk
LEFT JOIN orders_with_reasons rr ON ss.total_orders = rr.ws_order_number
ORDER BY ss.sales_year, ss.customer_gender;
