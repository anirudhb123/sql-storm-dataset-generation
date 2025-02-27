
WITH customer_info AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ca.ca_city, ca.ca_state, ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT ws.ws_order_number, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price, ws.ws_net_profit, d.d_year, w.w_warehouse_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
aggregated_sales AS (
    SELECT ci.c_customer_id, ci.c_first_name, ci.c_last_name, SUM(si.ws_quantity) AS total_quantity,
           SUM(si.ws_sales_price) AS total_sales, SUM(si.ws_net_profit) AS total_profit
    FROM customer_info ci
    JOIN sales_info si ON ci.c_customer_id = si.ws_order_number
    GROUP BY ci.c_customer_id, ci.c_first_name, ci.c_last_name
),
yearly_summary AS (
    SELECT d.d_year, SUM(as.total_quantity) AS yearly_quantity, SUM(as.total_sales) AS yearly_sales, 
           SUM(as.total_profit) AS yearly_profit
    FROM aggregated_sales as
    JOIN date_dim d ON as.d_year = d.d_year
    GROUP BY d.d_year
)
SELECT ys.d_year, ys.yearly_quantity, ys.yearly_sales, ys.yearly_profit
FROM yearly_summary ys
ORDER BY ys.d_year DESC;
