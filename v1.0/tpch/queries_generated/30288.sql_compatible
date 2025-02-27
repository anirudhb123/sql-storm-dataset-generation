
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT sup.s_suppkey, sup.s_name, sup.s_nationkey, sh.level + 1
    FROM supplier sup
    JOIN SupplierHierarchy sh ON sup.s_nationkey = sh.s_nationkey
    WHERE sup.s_acctbal IS NOT NULL AND sup.s_acctbal > 1000
),
NationAggregates AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
SupplierOrders AS (
    SELECT l.l_orderkey, l.l_partkey, o.o_orderkey,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
           l.l_extendedprice, l.l_discount, (l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
)
SELECT r.r_name, na.supplier_count, na.total_acctbal,
       SUM(so.discounted_price) AS total_discounted_price
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN NationAggregates na ON n.n_nationkey = na.n_nationkey
LEFT JOIN SupplierOrders so ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = so.l_partkey)
GROUP BY r.r_name, na.supplier_count, na.total_acctbal
HAVING SUM(so.discounted_price) > (SELECT AVG(discounted_price) FROM SupplierOrders)
ORDER BY total_discounted_price DESC
LIMIT 10;
