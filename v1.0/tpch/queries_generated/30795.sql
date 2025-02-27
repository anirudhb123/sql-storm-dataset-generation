WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CAST(NULL AS VARCHAR(100)) as Parent_Supplier
    FROM supplier s
    WHERE s.s_acctbal > 100000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           c.s_name as Parent_Supplier
    FROM supplier s
    JOIN SupplierCTE c ON s.s_nationkey = c.s_suppkey
    WHERE s.s_acctbal < c.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS CostRank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT r.r_name, 
       SUM(CASE WHEN os.TotalRevenue IS NOT NULL THEN os.TotalRevenue ELSE 0 END) AS TotalRevenue,
       AVG(psi.ps_supplycost) AS AvgSupplyCost,
       COUNT(DISTINCT c.c_custkey) AS DistinctCustomers,
       MAX(sct.s_acctbal) AS MaxSupplierBalance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderSummary os ON s.s_suppkey = os.o_orderkey
LEFT JOIN PartSupplierInfo psi ON s.s_nationkey = psi.s_nationkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN SupplierCTE sct ON s.s_suppkey = sct.s_suppkey
WHERE sct.Parent_Supplier IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(s.s_suppkey) > 10
ORDER BY TotalRevenue DESC;
