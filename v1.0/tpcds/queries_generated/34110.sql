
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count > ch.level
),

recent_sales AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions
    FROM store_sales s
    WHERE s.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY s.ss_item_sk
),
inventory_info AS (
    SELECT
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    GROUP BY i.inv_item_sk
),
sales_comparison AS (
    SELECT 
        r.item_sk,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(i.total_quantity, 0) AS total_quantity,
        CASE 
            WHEN COALESCE(r.total_sales, 0) > (COALESCE(i.total_quantity, 0) * 20) THEN 'Excessive Sales'
            WHEN COALESCE(r.total_sales, 0) < (COALESCE(i.total_quantity, 0) * 10) THEN 'Underperforming'
            ELSE 'Stable'
        END AS sales_status
    FROM recent_sales r
    FULL OUTER JOIN inventory_info i ON r.ss_item_sk = i.inv_item_sk
),
customer_sales AS (
    SELECT 
        ch.customer_sk,
        SUM(ws.ws_sales_price) AS customer_total_spent,
        COUNT(ws.ws_order_number) AS customer_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS spending_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_hierarchy ch ON c.c_customer_sk = ch.customer_sk
    GROUP BY ch.customer_sk
)

SELECT 
    ch.customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    cs.customer_total_spent,
    cs.customer_orders,
    sc.total_sales,
    sc.total_quantity,
    sc.sales_status
FROM customer_hierarchy ch
LEFT JOIN customer_sales cs ON ch.customer_sk = cs.customer_sk
LEFT JOIN sales_comparison sc ON cs.customer_orders = sc.item_sk
WHERE cs.spending_rank <= 10
ORDER BY cs.customer_total_spent DESC;
