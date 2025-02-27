WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
),
suppliers_with_products AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           COUNT(DISTINCT ps.ps_partkey) AS product_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
customer_order_summary AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
),
top_suppliers AS (
    SELECT s.*, 
           ROW_NUMBER() OVER (ORDER BY s.total_supply_cost DESC) AS rank
    FROM suppliers_with_products s
    WHERE s.product_count > 0
),
negative_orders AS (
    SELECT oo.o_orderkey, 
           oo.o_custkey,
           SUM(ROUND(oo.o_totalprice, 2)) AS negative_total_due
    FROM orders oo
    WHERE oo.o_totalprice < 0
    GROUP BY oo.o_orderkey, oo.o_custkey
),
final_summary AS (
    SELECT c.c_custkey, 
           c.c_name,
           COALESCE(no.negative_total_due, 0) AS negative_due,
           ts.s_name AS top_supplier_name,
           ts.product_count AS products_supplied,
           ts.total_supply_cost
    FROM customer_order_summary c
    LEFT JOIN negative_orders no ON c.c_custkey = no.o_custkey
    LEFT JOIN top_suppliers ts ON c.total_spent > ts.total_supply_cost
)
SELECT DISTINCT f.c_custkey, f.c_name, f.negative_due, 
       CASE WHEN f.total_supply_cost IS NULL THEN 'NA' ELSE f.top_supplier_name END AS top_supplier,
       f.products_supplied,
       CASE 
           WHEN f.negative_due > 0 THEN 'Outstanding Balance'
           ELSE 'All Settled'
       END AS account_status
FROM final_summary f
WHERE f.products_supplied IS NOT NULL
OR (f.negative_due > 0 AND f.products_supplied IS NULL)
ORDER BY f.negative_due DESC, f.c_custkey ASC;
