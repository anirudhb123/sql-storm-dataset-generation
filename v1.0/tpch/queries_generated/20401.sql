WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(s.s_name, ' - ', s.s_address) AS SupplierInfo,
           NULL::integer as ParentKey
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(s.s_name, ' (child) - ', s.s_address) AS SupplierInfo,
           sh.s_suppkey as ParentKey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
)

SELECT r.r_name, n.n_name,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS TotalReturned,
       AVG(NULLIF(l.l_quantity, 0)) AS AvgQuantity,
       COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS FinishedOrders,
       STRING_AGG(DISTINCT sh.SupplierInfo, '; ') AS SupplierDetails
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE r.r_name IS NOT NULL AND n.n_name LIKE 'A%'
GROUP BY r.r_name, n.n_name
HAVING SUM(COALESCE(l.l_discount, 0)) > 1000
ORDER BY TotalReturned DESC NULLS LAST
LIMIT 10;
