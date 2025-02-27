
WITH monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2020, 2021)
    GROUP BY d.d_year, d.d_month_seq
), 
customer_summary AS (
    SELECT 
        ca.ca_state,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender
), 
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_net_profit) > 5000
), 
inventory_status AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
)

SELECT 
    cs.ca_state,
    cs.cd_gender,
    ms.total_sales,
    ms.order_count,
    COUNT(DISTINCT tc.c_customer_id) AS high_profit_customer_count,
    is.total_quantity
FROM customer_summary cs
LEFT JOIN monthly_sales ms ON cs.total_orders > 0
LEFT JOIN top_customers tc ON tc.total_profit > 5000
LEFT JOIN inventory_status is ON cs.total_sales_amount > 10000
GROUP BY cs.ca_state, cs.cd_gender, ms.total_sales, ms.order_count, is.total_quantity
ORDER BY cs.ca_state, cs.cd_gender;
