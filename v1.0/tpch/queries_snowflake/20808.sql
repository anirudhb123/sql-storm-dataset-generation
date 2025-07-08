
WITH RECURSIVE NationCTE AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS Level
    FROM nation
    WHERE n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, Level + 1
    FROM nation n
    JOIN NationCTE cte ON n.n_regionkey = cte.n_regionkey
    WHERE n.n_name NOT LIKE 'Z%' AND Level < 5
),
SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS BalRank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING AVG(ps.ps_supplycost) > 50.00
)
SELECT 
    c.c_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS TotalReturned,
    AVG(pc.AvgSupplyCost) AS AvgPartCost,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    COUNT(DISTINCT n.n_nationkey) AS ActiveNations,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS CustRank
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN FilteredParts pc ON l.l_partkey = pc.p_partkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN SupplierCTE scte ON c.c_nationkey = scte.s_suppkey
WHERE 
    l.l_shipdate IS NOT NULL 
    AND (l.l_discount < 0.1 OR l.l_returnflag = 'N')
GROUP BY c.c_custkey, c.c_name, c.c_nationkey
HAVING SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) > 100.00 
   AND AVG(pc.AvgSupplyCost) < (SELECT MIN(AvgSupplyCost) FROM FilteredParts) 
ORDER BY CustRank, TotalOrders DESC
LIMIT 10 OFFSET CASE WHEN (SELECT COUNT(*) FROM nation) < 5 THEN 0 ELSE 1 END;
