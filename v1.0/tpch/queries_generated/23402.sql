WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, Level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_suppkey = cte.s_suppkey
    WHERE Level < 3
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 25
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) IS NOT NULL
),
FinalData AS (
    SELECT ps.s_name, ps.s_acctbal, ps.Level, ps.s_suppkey, p.total_available_qty, p.avg_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY ps.s_suppkey ORDER BY p.avg_supply_cost DESC) AS rn
    FROM SupplierCTE ps
    LEFT JOIN PartSummary p ON ps.s_suppkey IN (
        SELECT DISTINCT ps.s_suppkey 
        FROM partsupp ps 
        JOIN part p ON p.p_partkey = ps.ps_partkey 
        WHERE p.p_retailprice > 100.00 AND p.p_comment IS NOT NULL
    )
)
SELECT fd.s_name, fd.s_acctbal, fd.total_available_qty, fd.avg_supply_cost
FROM FinalData fd
WHERE fd.total_available_qty IS NOT NULL
AND fd.avg_supply_cost BETWEEN (SELECT AVG(avg_supply_cost) FROM PartSummary) AND (SELECT MAX(avg_supply_cost) FROM PartSummary)
ORDER BY fd.s_acctbal DESC, fd.total_available_qty ASC
LIMIT 10;
