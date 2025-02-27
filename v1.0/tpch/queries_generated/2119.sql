WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent,
        AVG(o.o_totalprice) AS AvgOrderValue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
),
ProductSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS TotalSold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.s_name AS SupplierName,
    ns.n_name AS NationName,
    ps.TotalSold,
    ps.TotalRevenue,
    os.TotalOrders,
    os.TotalSpent,
    os.AvgOrderValue
FROM RankedSuppliers r
LEFT JOIN nation ns ON ns.n_nationkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_nationkey = r.s_suppkey
)
JOIN ProductSales ps ON ps.TotalSold > 100
JOIN OrderSummary os ON os.TotalSpent > 1000
WHERE r.RankInNation = 1
ORDER BY ns.n_name, ps.TotalRevenue DESC
LIMIT 50;
