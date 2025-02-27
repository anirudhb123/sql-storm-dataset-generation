
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighSupplySuppliers AS (
    SELECT * 
    FROM RankedSuppliers 
    WHERE Rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalRevenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        AND l.l_returnflag = 'N'
    GROUP BY c.c_custkey
),
SupplierNation AS (
    SELECT 
        s.s_suppkey, 
        n.n_name,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, n.n_name
)
SELECT 
    co.c_custkey,
    co.OrderCount, 
    co.TotalRevenue,
    COUNT(DISTINCT ss.s_suppkey) AS ActiveSuppliers,
    SUM(CASE WHEN sn.n_name = 'FRANCE' THEN sn.UniquePartsSupplied ELSE 0 END) AS FrenchPartSupplies,
    STRING_AGG(DISTINCT sn.n_name, ', ') FILTER (WHERE sn.UniquePartsSupplied > 0) AS ActiveSupplierNations
FROM CustomerOrders co
LEFT JOIN HighSupplySuppliers ss ON co.TotalRevenue > (SELECT AVG(TotalRevenue) FROM CustomerOrders)
LEFT JOIN SupplierNation sn ON ss.s_suppkey = sn.s_suppkey
WHERE co.TotalRevenue IS NOT NULL
GROUP BY co.c_custkey, co.OrderCount, co.TotalRevenue
ORDER BY co.TotalRevenue DESC, co.OrderCount DESC
LIMIT 10;
