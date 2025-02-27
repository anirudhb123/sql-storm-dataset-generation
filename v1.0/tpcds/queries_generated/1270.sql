
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2022)
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM customer c
    JOIN customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.order_count,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    COALESCE((SELECT COUNT(DISTINCT wr.wr_order_number) 
              FROM web_returns wr 
              WHERE wr.wr_returning_customer_sk = tc.c_customer_sk), 0) AS return_count,
    COALESCE(AVG(wh.wholesale_cost), 0) AS avg_item_cost
FROM top_customers tc
LEFT JOIN item i ON tc.total_web_sales = i.i_item_sk
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
WHERE tc.order_count > 5
GROUP BY tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_web_sales, tc.order_count, tc.sales_rank
HAVING SUM(tc.total_web_sales) > 1000
ORDER BY tc.total_web_sales DESC;
