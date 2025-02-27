WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 10
),
PriceStats AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           COUNT(l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
NationCounts AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, 
       np.n_name, 
       SUM(ps.avg_price) AS total_avg_price,
       AVG(np.supplier_count) AS avg_supplier_count,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), ', ') AS supplier_details
FROM region r
LEFT JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN PriceStats ps ON np.n_nationkey = ps.p_partkey
LEFT JOIN lineitem l ON ps.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy s ON ps.p_partkey = s.s_suppkey
WHERE r.r_name IS NOT NULL
  AND o.o_orderdate >= '2022-01-01'
  AND o.o_orderstatus IN ('O', 'P')
GROUP BY r.r_name, np.n_name
HAVING SUM(ps.avg_price) > 10000
ORDER BY total_avg_price DESC, avg_supplier_count ASC;
