WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.level < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
      AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        WHERE s2.s_nationkey IN (SELECT n_nationkey FROM NationHierarchy)
    )
)
SELECT 
    r.r_name AS Region,
    COALESCE(ns.n_name, 'Unknown') AS Nation,
    fs.s_name AS SupplierName,
    fs.s_acctbal AS SupplierBalance,
    SUM(os.TotalRevenue) AS TotalSales,
    SUM(ss.TotalSupplyCost) AS TotalSupplierCost
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_size BETWEEN 20 AND 50
    )
)
LEFT JOIN OrderDetails os ON os.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_shipmode IN ('AIR', 'TRUCK')
)
LEFT JOIN SupplierStats ss ON ss.s_suppkey = fs.s_suppkey
GROUP BY r.r_name, ns.n_name, fs.s_name, fs.s_acctbal
ORDER BY r.r_name, TotalSales DESC
LIMIT 50;
