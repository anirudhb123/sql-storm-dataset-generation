
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS transaction_rank
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_spent,
        ss.total_transactions,
        (CASE 
            WHEN ss.total_spent IS NULL THEN 'Unknown'
            ELSE 'Known'
        END) AS spending_category
    FROM sales_summary ss
    JOIN customer c ON ss.c_customer_sk = c.c_customer_sk
    WHERE ss.transaction_rank <= 10
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ss.ss_item_sk) AS items_available,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    LEFT JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN store_sales ss ON inv.inv_item_sk = ss.ss_item_sk
    GROUP BY w.w_warehouse_id
),
sales_analysis AS (
    SELECT
        t.warehouse_id,
        tc.full_name,
        tc.total_spent,
        ti.items_available,
        ti.total_inventory,
        (tc.total_spent / NULLIF(ti.total_inventory, 0)) AS spending_per_inventory
    FROM top_customers tc
    JOIN warehouse_info ti ON 1 = 1 -- Cross join for exploratory analysis
)
SELECT 
    s.warehouse_id,
    s.full_name,
    s.total_spent,
    s.items_available,
    s.total_inventory,
    s.spending_per_inventory,
    CASE 
        WHEN s.spending_per_inventory < 1 THEN 'Low Activity'
        WHEN s.spending_per_inventory BETWEEN 1 AND 5 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END AS activity_level
FROM sales_analysis s
WHERE s.total_inventory IS NOT NULL 
ORDER BY s.total_spent DESC, s.items_available ASC
LIMIT 20;
