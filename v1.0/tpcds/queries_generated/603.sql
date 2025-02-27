
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
),
sales_aggregates AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_customer_sk = ws.bill_customer_sk 
          AND c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE)
    )
    GROUP BY ws.bill_customer_sk
),
most_profitable AS (
    SELECT 
        sa.bill_customer_sk,
        sa.total_profit,
        ROW_NUMBER() OVER (ORDER BY sa.total_profit DESC) AS rank
    FROM sales_aggregates sa
),
customer_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr.'
            WHEN cd.cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    ci.salutation,
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    mp.total_profit,
    COUNT(DISTINCT rs.ws_order_number) AS count_of_orders,
    AVG(rs.ws_sales_price) AS average_sales_price
FROM customer_info ci
LEFT JOIN most_profitable mp ON ci.c_customer_sk = mp.bill_customer_sk
LEFT JOIN ranked_sales rs ON rs.ws_item_sk IN (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_net_profit > 0
)
WHERE mp.rank <= 10 OR mp.total_profit IS NULL
GROUP BY ci.salutation, ci.c_customer_sk, ci.cd_gender, ci.cd_marital_status, mp.total_profit
ORDER BY mp.total_profit DESC NULLS LAST;
