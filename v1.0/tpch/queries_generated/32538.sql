WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_nationkey, Level + 1
    FROM supplier sh
    INNER JOIN SupplierHierarchy shier ON sh.s_nationkey = shier.s_nationkey
    WHERE sh.s_acctbal < shier.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS RegionName,
    n.n_name AS NationName,
    p.p_name AS PartName,
    COALESCE(SUM(ps.ps_availqty), 0) AS TotalAvailableQuantity,
    COALESCE(SUM(ps.ps_supplycost), 0) AS TotalSupplyCost,
    SUM(os.TotalRevenue) AS DailyRevenue,
    CASE 
        WHEN COUNT(DISTINCT sh.s_suppkey) > 0 THEN 'Suppliers Exist'
        ELSE 'No Suppliers'
    END AS SupplierStatus
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN OrderSummary os ON os.o_orderdate = CURRENT_DATE
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_size > 10
  AND p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY r.r_name, n.n_name, p.p_name
HAVING TotalAvailableQuantity > 100
   OR SUM(os.TotalRevenue) > 1000
ORDER BY RegionName, NationName, PartName;
