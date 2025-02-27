WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty, 0 AS Level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty, Level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE ps.ps_availqty > 0 AND Level < 3
),
AggregatedSales AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS TotalSales,
        COUNT(o.o_orderkey) AS OrderCount,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS SalesRank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
FilteredProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS AvgSupplyCost,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    n.n_name AS Nation,
    fp.p_name AS Product,
    fp.AvgSupplyCost,
    asales.TotalSales,
    asales.OrderCount
FROM AggregatedSales asales
JOIN nation n ON n.n_nationkey = asales.c_nationkey
JOIN FilteredProducts fp ON fp.SupplierCount > 5
LEFT OUTER JOIN SupplyChain sc ON sc.ps_partkey = fp.p_partkey
WHERE asales.SalesRank <= 5
  AND (fp.AvgSupplyCost IS NOT NULL OR n.n_comment IS NULL)
ORDER BY asales.TotalSales DESC, fp.AvgSupplyCost ASC;
