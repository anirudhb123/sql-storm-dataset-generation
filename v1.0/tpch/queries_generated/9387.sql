WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 500
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
)
SELECT r.r_name AS RegionName, 
       COUNT(DISTINCT hs.s_suppkey) AS HighValueSuppliers,
       SUM(hp.total_available) AS TotalAvailableQty,
       SUM(os.net_revenue) AS TotalNetRevenue
FROM RankedSuppliers rs
JOIN region r ON rs.s_nationkey = r.r_regionkey
JOIN HighValueParts hp ON hp.ps_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
)
JOIN OrderStats os ON os.o_orderkey IN (
    SELECT DISTINCT l.l_orderkey
    FROM lineitem l
)
WHERE rs.SupplierRank <= 3
GROUP BY r.r_name
ORDER BY TotalNetRevenue DESC;
