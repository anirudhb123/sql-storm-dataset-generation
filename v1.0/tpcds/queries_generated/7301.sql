
WITH sales_summary AS (
    SELECT
        customer.c_customer_id,
        SUM(COALESCE(web_sales.ws_net_profit, 0) + COALESCE(store_sales.ss_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT web_sales.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS total_store_orders,
        COUNT(DISTINCT web_sales.ws_item_sk) AS unique_web_items,
        COUNT(DISTINCT store_sales.ss_item_sk) AS unique_store_items,
        AVG(COALESCE(web_sales.ws_net_paid, 0)) AS avg_web_order_value,
        AVG(COALESCE(store_sales.ss_net_paid, 0)) AS avg_store_order_value
    FROM
        customer
    LEFT JOIN web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    LEFT JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
    WHERE
        customer.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY
        customer.c_customer_id
),
demographics_analysis AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(total_net_profit) AS total_profit
    FROM
        sales_summary
    JOIN customer_demographics ON customer_demographics.cd_demo_sk = (
            SELECT c_current_cdemo_sk FROM customer WHERE customer.c_customer_id = sales_summary.c_customer_id
        )
    GROUP BY
        cd_gender
)
SELECT
    da.cd_gender,
    da.customer_count,
    da.total_profit,
    da.total_profit / NULLIF(da.customer_count, 0) AS avg_profit_per_customer
FROM
    demographics_analysis da
ORDER BY
    da.total_profit DESC
LIMIT 10;
