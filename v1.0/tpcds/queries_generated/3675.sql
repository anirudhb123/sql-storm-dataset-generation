
WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        COALESCE(ws.ws_net_paid_inc_tax, 0) AS net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_first_name, c.c_last_name) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_selling_items AS (
    SELECT
        item.i_item_sk,
        item.i_product_name,
        SUM(sd.ws_quantity) AS total_quantity_sold
    FROM sales_data sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_sk, item.i_product_name
    HAVING SUM(sd.ws_quantity) > 100
),
item_with_rank AS (
    SELECT
        ti.i_item_sk,
        ti.i_product_name,
        ti.total_quantity_sold,
        RANK() OVER (ORDER BY ti.total_quantity_sold DESC) AS rank
    FROM top_selling_items ti
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    SUM(sd.net_paid) AS total_spent,
    COUNT(DISTINCT sd.ws_order_number) AS number_of_orders,
    iwr.total_quantity_sold
FROM customer_info ci
JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
JOIN item_with_rank iwr ON sd.ws_item_sk = iwr.i_item_sk
WHERE ci.rn = 1
  AND ci.cd_marital_status = 'M'
  AND (sd.net_paid > (SELECT AVG(net_paid) FROM sales_data)) 
GROUP BY ci.c_first_name, ci.c_last_name, ci.cd_gender, iwr.total_quantity_sold
ORDER BY total_spent DESC, number_of_orders DESC
FETCH FIRST 50 ROWS ONLY;
