WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name, p.p_retailprice,
           1 AS Level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 20
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name, p.p_retailprice,
           sc.Level + 1
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT n.n_name AS Nation, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
       COUNT(DISTINCT o.o_orderkey) AS OrderCount,
       AVG(c.c_acctbal) AS AvgAccountBalance,
       STRING_AGG(DISTINCT p.p_name, ', ') AS PartNames
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
WHERE o.o_orderstatus IN ('O', 'F')
  AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (c.c_mktsegment = 'BUILDING' OR c.c_acctbal IS NULL)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY TotalRevenue DESC
LIMIT 5;
