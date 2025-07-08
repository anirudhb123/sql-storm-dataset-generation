WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal AND sh.level < 5
),
part_details AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count, 
       SUM(pd.total_available) AS total_parts_available,
       COALESCE(SUM(co.total_spent), 0) AS total_spent,
       MAX(sh.level) AS max_supplier_level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN part_details pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN customer_orders co ON co.total_spent > 1000
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE r.r_name LIKE '%East%' 
  AND (pd.avg_supply_cost IS NULL OR pd.avg_supply_cost > 50)
GROUP BY r.r_name
ORDER BY r.r_name;