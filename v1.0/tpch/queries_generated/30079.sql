WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 10000  -- Base case: selecting high-value suppliers
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, cs.Level + 1
    FROM supplier s
    JOIN CTE_Supplier cs ON s.s_acctbal < cs.s_acctbal -- Recursive case: lower-value suppliers linked
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2023-10-01'
    GROUP BY l.l_orderkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS TotalAvailable
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrdersData AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS RevenueRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
)
SELECT r.r_name, 
       COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
       SUM(t.TotalRevenue) AS TotalRevenue,
       AVG(s.s_acctbal) AS AvgSupplierBalance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrdersData o ON o.o_orderkey = t.l_orderkey
LEFT JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
LEFT JOIN CTE_Supplier cs ON cs.s_suppkey = s.s_suppkey
WHERE o.RevenueRank <= 5  -- Filter for top segments by revenue
GROUP BY r.r_name
HAVING SUM(t.TotalRevenue) IS NOT NULL AND COUNT(DISTINCT o.o_orderkey) > 10  -- Eliminate regions with insufficient orders
ORDER BY TotalRevenue DESC, r.r_name;
