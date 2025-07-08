
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           CAST(s_name AS VARCHAR(55)) AS FullName, 
           0 AS Level
    FROM supplier
    WHERE s_nationkey IN (
        SELECT n_nationkey 
        FROM nation 
        WHERE n_name LIKE '%land%'
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(sh.FullName, ' -> ', s.s_name),
           sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
)

SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS OrdersCount,
    SUM(l.l_extendedprice * (1 - COALESCE(l.l_discount, 0))) AS TotalRevenue,
    MAX(l.l_shipdate) AS LastShipDate,
    AVG(CASE WHEN o.o_orderstatus = 'O' THEN l.l_quantity END) AS AvgOpenOrderQty,
    LISTAGG(DISTINCT CONCAT(s.s_name, ' (', l.l_returnflag, ')'), ', ') WITHIN GROUP (ORDER BY s.s_name) AS Suppliers
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
  AND (o.o_orderstatus IS NULL OR o.o_orderstatus IN ('O', 'F'))
  AND (s.s_acctbal IS NULL OR s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey))
GROUP BY p.p_partkey, p.p_name, s.s_name, l.l_returnflag
HAVING COUNT(DISTINCT l.l_orderkey) > 0 
   AND SUM(l.l_extendedprice * (1 - COALESCE(l.l_discount, 0))) > 5000
ORDER BY TotalRevenue DESC
LIMIT 10;
