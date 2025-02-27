WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name AS RegionName, RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM RankedSuppliers r
    JOIN supplier s ON r.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, r.r_regionkey
)
SELECT ts.RegionName, COUNT(*) AS SupplierCount, AVG(ts.s_acctbal) AS AvgAccountBalance
FROM TopSuppliers ts
WHERE ts.Rank <= 5
GROUP BY ts.RegionName
ORDER BY SupplierCount DESC, AvgAccountBalance DESC;
