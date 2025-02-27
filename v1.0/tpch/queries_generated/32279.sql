WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS depth
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
), NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, n.n_comment
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT p.p_name, 
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_acctbal,
       STRING_AGG(DISTINCT nr.r_name) AS regions_supplied
FROM part p
LEFT OUTER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN SupplierHierarchy s ON ps.ps_suppkey = s.s_suppkey
JOIN NationRegion nr ON s.s_nationkey = nr.n_nationkey
WHERE COALESCE(p.p_size, 0) > 10
  AND (s.s_acctbal > 500 OR p.p_retailprice < 100)
GROUP BY p.p_name
ORDER BY total_revenue DESC, supplier_count ASC
FETCH FIRST 10 ROWS ONLY;
