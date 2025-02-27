WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS cost_rank
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS cost_rank
    FROM SupplyChain
    JOIN partsupp ps ON SupplyChain.ps_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE SupplyChain.cost_rank < 5
), 
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT l.l_partkey) AS number_of_parts, 
           (CASE WHEN SUM(l.l_tax) = 0 THEN NULL ELSE SUM(l.l_extendedprice * l.l_tax) END) AS tax_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(s.ps_availqty) AS total_avail_qty, 
       COALESCE(MAX(os.total_revenue), 0) AS max_revenue, 
       COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returned_items
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN SupplyChain s ON c.c_custkey = s.s_nationkey
LEFT JOIN OrderSummary os ON s.ps_partkey = os.o_orderkey
LEFT JOIN lineitem l ON os.o_orderkey = l.l_orderkey
WHERE r.r_name NOT LIKE '%e%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5 AND 
       COUNT(DISTINCT s.s_suppkey) > 1 OR 
       SUM(COALESCE(s.ps_availqty, 0)) > 1000
ORDER BY customer_count DESC;
