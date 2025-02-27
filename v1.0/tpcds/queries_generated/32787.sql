
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_item_desc,
        i.i_current_price,
        1 AS hierarchy_level
    FROM item i
    WHERE i.i_current_price IS NOT NULL
    UNION ALL
    SELECT 
        ih.i_item_sk, 
        ih.i_item_id, 
        CONCAT(ih.i_item_desc, ' > ', ih2.i_item_desc),
        ih2.i_current_price,
        ih.hierarchy_level + 1
    FROM ItemHierarchy ih
    JOIN item ih2 ON ih.i_item_sk = ih2.i_item_sk
    WHERE ih2.i_current_price IS NOT NULL AND ih.hierarchy_level < 3
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS avg_transaction_value
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    d.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_transaction_value,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.total_sales DESC) AS sales_rank,
    th.hierarchy_level,
    th.i_item_desc,
    th.i_current_price,
    tc.c_first_name || ' ' || tc.c_last_name AS top_customer
FROM SalesSummary ss
LEFT JOIN date_dim d ON d.d_year = ss.d_year
LEFT JOIN ItemHierarchy th ON th.i_item_sk IN (SELECT DISTINCT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_order_number IN (SELECT ss_ticket_number FROM store_sales WHERE ss_net_paid > 100))
LEFT JOIN TopCustomers tc ON tc.total_spent = (
    SELECT MAX(total_spent)
    FROM TopCustomers
)
WHERE d.d_year IS NOT NULL
ORDER BY d.d_year DESC, ss.total_sales DESC;
