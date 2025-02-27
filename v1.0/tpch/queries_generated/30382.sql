WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 1000
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 2 AND AVG(ps.ps_supplycost) < 50
)

SELECT c.c_name AS customer_name,
       r.r_name AS region_name,
       p.p_name AS part_name,
       psi.avg_supply_cost,
       psi.supplier_count,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_value,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(l.l_extendedprice) AS total_order_value,
       sh.hierarchy_level AS supplier_hierarchy_level
FROM top_customers c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN part_supplier_info psi ON l.l_partkey = psi.p_partkey
LEFT JOIN supplier_hierarchy sh ON psi.supplier_count = sh.s_suppkey
GROUP BY c.c_name, r.r_name, p.p_name, psi.avg_supply_cost, psi.supplier_count, sh.hierarchy_level
ORDER BY total_order_value DESC, customer_name;
