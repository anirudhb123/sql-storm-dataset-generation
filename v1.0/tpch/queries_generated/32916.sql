WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           s.s_nationkey, 
           (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey) AS nation_name,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           s.s_nationkey, 
           (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey) AS nation_name,
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_nationkey
)
SELECT p.p_partkey, p.p_name, 
       SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_qty,
       COUNT(DISTINCT l.l_orderkey) AS total_orders,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank,
       r.r_name AS region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate >= DATE '2023-01-01' 
  AND l.l_shipdate < DATE '2024-01-01' 
  AND (l.l_returnflag = 'R' OR l.l_linestatus = 'O')
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING SUM(COALESCE(ps.ps_availqty, 0)) > 50
ORDER BY order_rank, total_available_qty DESC;
