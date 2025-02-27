WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.level * 5000
),
latest_orders AS (
    SELECT o.o_orderkey, o.o_custkey, MAX(o.o_orderdate) AS latest_order_date
    FROM orders o
    GROUP BY o.o_orderkey, o.o_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_linenumber) AS line_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
    SUM(CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) AS total_supply_cost,
    AVG(COALESCE(c.c_acctbal, 0)) AS avg_customer_balance,
    SUM(ls.total_price) AS order_total,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ls.total_price) DESC) AS region_order
FROM nation n
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
JOIN latest_orders lo ON c.c_custkey = lo.o_custkey
JOIN lineitem_summary ls ON lo.o_orderkey = ls.l_orderkey
WHERE n.n_name NOT IN ('NA')
AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = lo.o_orderkey AND l.l_tax > 0)
GROUP BY n.n_name
HAVING COUNT(DISTINCT ps.ps_partkey) > 5
   AND AVG(COALESCE(c.c_acctbal, NULL)) BETWEEN 1000 AND 5000
   AND SUM(CASE WHEN ls.line_count >= 3 THEN 1 ELSE 0 END) > 0
ORDER BY region_order, n.n_name;
