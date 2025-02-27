WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON p.p_partkey = s.s_suppkey
    WHERE sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT co.c_custkey, co.c_name, co.total_orders, co.total_spent,
           ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM customer_orders co
),
high_value_customers AS (
    SELECT r.custkey, r.c_name, r.total_orders, r.total_spent
    FROM ranked_orders r
    WHERE r.rank <= 10
),
final_report AS (
    SELECT s.s_name AS supplier_name, 
           COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COALESCE(sh.level, -1) AS supplier_level,
           hvc.total_spent AS customer_spending
    FROM supplier_hierarchy sh
    FULL OUTER JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN high_value_customers hvc ON hvc.c_custkey = l.l_orderkey
    GROUP BY s.s_name, sh.level, hvc.total_spent
)
SELECT f.supplier_name, 
       f.supplied_parts, 
       f.total_sales, 
       CASE 
           WHEN f.supplier_level = -1 THEN 'No Hierarchy'
           ELSE CONCAT('Level ', f.supplier_level)
       END AS supplier_level,
       COALESCE(f.customer_spending, 0) AS customer_spending
FROM final_report f
WHERE f.total_sales > 10000
ORDER BY f.total_sales DESC;
