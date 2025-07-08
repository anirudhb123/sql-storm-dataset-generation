WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey) AS nation_name
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey) AS nation_name
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
)

SELECT p.p_name, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_account_balance,
       MAX(CASE WHEN l.l_shipdate < '1996-01-01' THEN l.l_extendedprice ELSE NULL END) AS max_old_shipment_value
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_size >= 15
  AND o.o_orderstatus IN ('O', 'F')
  AND l.l_returnflag = 'N'
GROUP BY p.p_name
HAVING SUM(l.l_quantity) > 100
ORDER BY total_revenue DESC
LIMIT 10;