
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
    )
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        SUM(CASE WHEN rs.price_rank = 1 THEN rs.ws_sales_price * rs.ws_quantity ELSE 0 END) AS top_sales,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders
    FROM ranked_sales rs
    JOIN item ON rs.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        CASE 
            WHEN ci.total_spent IS NULL THEN 'No Purchases'
            WHEN ci.total_spent < 100 THEN 'Low Spender'
            WHEN ci.total_spent BETWEEN 100 AND 500 THEN 'Moderate Spender'
            ELSE 'High Spender'
        END AS spending_category,
        AS.item_id,
        AS.top_sales,
        AS.total_orders,
        COUNT(*) OVER () AS total_customers
    FROM customer_info ci
    LEFT JOIN aggregated_sales AS ON ci.c_customer_id = aggregated_sales.by_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.spending_category,
    fr.item_id,
    fr.top_sales,
    fr.total_orders,
    fr.total_customers
FROM final_report fr
ORDER BY fr.total_spent DESC NULLS LAST, fr.cd_gender, fr.c_customer_id;
