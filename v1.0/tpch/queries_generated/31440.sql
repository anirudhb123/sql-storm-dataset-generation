WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.custkey <> ch.c_custkey AND c.c_acctbal < ch.c_acctbal
),
SupplierCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighlyRatedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT ch.c_name AS Customer, 
       COUNT(DISTINCT o.o_orderkey) AS OrderCount, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSpent,
       s.s_name AS SupplierName,
       sc.total_cost AS SupplierTotalCost,
       p.p_name AS PartName,
       ROW_NUMBER() OVER (PARTITION BY ch.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Rank,
       CASE 
           WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
           ELSE 'Has Orders'
       END AS OrderStatus
FROM CustomerHierarchy ch
LEFT JOIN orders o ON ch.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierCosts sc ON l.l_partkey = sc.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
JOIN HighlyRatedParts p ON l.l_partkey = p.p_partkey
WHERE ch.level <= 3 AND s.s_acctbal IS NOT NULL
GROUP BY ch.c_name, s.s_name, sc.total_cost, p.p_name
ORDER BY TotalSpent DESC NULLS LAST;
