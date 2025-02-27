WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)  -- starting with the supplier with the lowest key
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey != sh.s_suppkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT
    ps.ps_partkey,
    p.p_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    RANK() OVER (PARTITION BY r.r_name ORDER BY AVG(s.s_acctbal) DESC) AS region_rank,
    sh.level AS supplier_level
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN customer_summary cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY c.c_custkey LIMIT 1) 
LEFT JOIN region_summary r ON 1=1  -- Cross join for aggregating information
JOIN supplier_hierarchy sh ON sh.s_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT MIN(c_custkey) FROM customer))
WHERE p.p_retailprice > 100.00 
  AND sh.level < 3
  AND EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
      AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
  )
ORDER BY total_spent_by_customer DESC, p.p_name;
