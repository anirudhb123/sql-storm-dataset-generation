WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- base case
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 3 AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
)
SELECT DISTINCT r.r_name, count(DISTINCT n.n_nationkey) AS nation_count,
       (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) AS customer_count,
       COALESCE(SUM(oss.total_revenue), 0) AS total_order_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN order_summary oss ON oss.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = sh.s_suppkey)
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY nation_count DESC, total_order_revenue DESC;
