
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_sales_price) AS total_spent 
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           sh.total_orders + COUNT(ws.ws_order_number),
           sh.total_spent + SUM(ws.ws_sales_price)
    FROM customer c
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_orders, sh.total_spent
),
order_stats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT o.ws_order_number) AS order_count,
        SUM(o.ws_sales_price) AS total_sales,
        AVG(o.ws_sales_price) AS average_order_value
    FROM web_sales o
    LEFT JOIN customer_address ca ON o.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        sh.total_spent,
        rd.r_reason_desc AS return_reason,
        ROW_NUMBER() OVER (ORDER BY sh.total_spent DESC) AS rank
    FROM sales_hierarchy sh
    LEFT JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN reason rd ON wr.wr_reason_sk = rd.r_reason_sk
    WHERE sh.total_spent IS NOT NULL
)
SELECT 
    hv.customer_name,
    hv.total_spent,
    os.order_count,
    os.total_sales,
    os.average_order_value,
    hv.return_reason
FROM high_value_customers hv
JOIN order_stats os ON hv.rank <= 100
WHERE hv.total_spent > 1000
ORDER BY hv.total_spent DESC;
