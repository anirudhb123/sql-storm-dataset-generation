WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 as Level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, rs.Level + 1
    FROM supplier s
    JOIN RecursiveSupplier rs ON s.s_nationkey = rs.s_nationkey
    WHERE s.s_acctbal < rs.s_acctbal
),

RegionAgg AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) as NationCount
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),

PartSupplierDetails AS (
    SELECT p.p_name, ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS Rank,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS SupplyRank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 50 AND ps.ps_supplycost IS NOT NULL
),

CustomerOrderTotals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS TotalOrderValue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 5000
),

FinalView AS (
    SELECT p.p_name, r.r_name, s.s_name, ps.ps_availqty, ps.ps_supplycost, c.TotalOrderValue,
           CASE WHEN c.TotalOrderValue IS NOT NULL AND rs.s_name IS NOT NULL 
                THEN 'Valid Supplier' ELSE 'Invalid Supplier' END AS SupplierStatus
    FROM PartSupplierDetails ps
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
    LEFT JOIN CustomerOrderTotals c ON c.c_custkey = (
        SELECT o.o_custkey
        FROM orders o
        WHERE o.o_orderstatus = 'O' AND o.o_totalprice = c.TotalOrderValue
        LIMIT 1
    )
    LEFT JOIN RecursiveSupplier rs ON rs.s_suppkey = s.s_suppkey
)

SELECT r.r_name, 
       SUM(CASE WHEN f.SupplierStatus = 'Valid Supplier' THEN f.ps_supplycost ELSE 0 END) AS ValidSupplierCosts,
       COUNT(DISTINCT f.s_name) AS DistinctSuppliers,
       COUNT(*) FILTER (WHERE f.ps_availqty IS NULL) AS NullAvailabilityCount,
       COALESCE(AVG(f.TotalOrderValue), 0) AS AvgOrderAmount
FROM FinalView f
JOIN region r ON f.r_name = r.r_name
GROUP BY r.r_name
HAVING SUM(f.ps_supplycost) > 10000
ORDER BY ValidSupplierCosts DESC, DistinctSuppliers DESC;
