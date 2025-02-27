WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM supplier s
    JOIN nation n ON s.n_nationkey = n.n_nationkey
    WHERE n.n_comment IS NOT NULL
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Undefined Value'
               WHEN c.c_acctbal > 10000 THEN 'Platinum'
               ELSE 'Regular'
           END AS CustomerTier
    FROM customer c
    WHERE c.c_mktsegment IN ('AUTOMOBILE', 'FURNITURE')
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           ps.ps_availqty,
           ps.ps_supplycost,
           p.p_name,
           p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 10 AND 20
)
SELECT r.r_name,
       SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS Revenue,
       COUNT(DISTINCT o.o_orderkey) AS OrderCount,
       AVG(s.s_acctbal) AS AvgSupplierBalance
FROM supplier s
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
FULL OUTER JOIN SupplierPartDetails spd ON s.s_suppkey = spd.ps_suppkey
INNER JOIN lineitem lp ON spd.ps_partkey = lp.l_partkey
JOIN orders o ON lp.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.n_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (CASE
          WHEN c.c_acctbal IS NULL THEN 0
          WHEN s.s_acctbal > 5000 THEN 1
          ELSE 0
       END) = 1
AND (lp.l_returnflag = 'N' OR lp.l_returnflag IS NULL)
AND EXISTS (SELECT 1
            FROM HighValueCustomers hvc
            WHERE hvc.c_custkey = c.c_custkey 
              AND hvc.CustomerTier = 'Platinum')
GROUP BY r.r_name
HAVING SUM(lp.l_extendedprice) > 100000
ORDER BY Revenue DESC;
