
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year) AS rn,
        COUNT(*) OVER (PARTITION BY c.c_customer_sk) AS total_entries
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk > (
        SELECT MAX(d_date_sk) - 365 FROM date_dim
    )
    GROUP BY ws_bill_customer_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws_quantity) AS total_sold,
        AVG(ws_list_price) AS avg_list_price,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
),
return_summary AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt_inc_tax) AS total_return_amount,
        COUNT(cr_order_number) AS return_orders
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_state,
    ss.total_profit,
    ss.total_orders,
    ia.total_sold,
    ia.avg_list_price,
    ia.total_discounts,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    NULLIF(ss.total_orders, 0) AS orders_count_adjusted,
    CASE 
        WHEN ss.total_orders = 0 THEN 'No Orders Yet'
        ELSE 'Active Customer'
    END AS customer_status
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN item_summary ia ON ia.total_sold > 0
LEFT JOIN return_summary rs ON ci.c_customer_sk = rs.cr_returning_customer_sk
WHERE ci.rn = 1
ORDER BY ci.c_customer_id;
