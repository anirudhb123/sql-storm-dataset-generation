WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
), RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(DAY, -30, GETDATE())
), SupplierOrderDetails AS (
    SELECT 
        r.suppkey, 
        r.s_name, 
        r.TotalSupplyCost,
        o.o_orderkey, 
        o.o_totalprice
    FROM RankedSuppliers r
    LEFT JOIN lineitem l ON r.s_suppkey = l.l_suppkey
    LEFT JOIN RecentOrders o ON l.l_orderkey = o.o_orderkey
    WHERE r.rn <= 3 -- Getting top 3 suppliers per nation
)
SELECT 
    s.s_name AS SupplierName,
    COALESCE(SUM(so.o_totalprice), 0) AS TotalOrderValue,
    COUNT(DISTINCT so.o_orderkey) AS NumberOfOrders,
    CASE 
        WHEN SUM(so.o_totalprice) IS NOT NULL 
        THEN SUM(so.o_totalprice) / NULLIF(COUNT(DISTINCT so.o_orderkey), 0)
        ELSE 0 
    END AS AverageOrderValue
FROM RankedSuppliers r
LEFT JOIN SupplierOrderDetails so ON r.s_suppkey = so.suppkey
GROUP BY s.s_name
HAVING SUM(so.o_totalprice) > 10000
ORDER BY AverageOrderValue DESC;
