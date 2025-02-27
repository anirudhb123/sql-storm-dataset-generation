WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
),
order_quantity AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
nation_with_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sh.s_name AS supplier_name, 
    sh.level AS hierarchy_level,
    nc.n_name AS nation_name, 
    nc.r_name AS region_name,
    tc.total_spent, 
    oq.total_quantity,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Orders'
        WHEN oq.total_quantity > 100 THEN 'High Quantity'
        ELSE 'Normal'
    END AS order_status
FROM supplier_hierarchy sh
LEFT JOIN nation_with_region nc ON sh.s_nationkey = nc.n_nationkey
LEFT JOIN top_customers tc ON tc.c_custkey = sh.s_suppkey
LEFT JOIN order_quantity oq ON oq.o_orderkey = sh.s_suppkey
WHERE sh.level < 5
ORDER BY sh.level DESC, tc.total_spent DESC;
