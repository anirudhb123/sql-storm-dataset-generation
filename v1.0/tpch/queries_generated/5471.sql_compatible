
WITH RegionSupplier AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount, 
        SUM(s.s_acctbal) AS TotalAccountBalance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_nationkey, 
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders, 
        SUM(o.o_totalprice) AS TotalSales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
PartSupplierSales AS (
    SELECT 
        ps.ps_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rs.r_name AS Region,
    rs.SupplierCount,
    rs.TotalAccountBalance,
    cos.TotalOrders,
    cos.TotalSales,
    ps.ps_partkey AS PartKey,
    ps.TotalSales AS PartTotalSales
FROM 
    RegionSupplier rs
JOIN 
    CustomerOrderStats cos ON rs.r_name IN (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = cos.c_nationkey
    )
JOIN 
    PartSupplierSales ps ON ps.TotalSales > 10000
ORDER BY 
    rs.TotalAccountBalance DESC, 
    cos.TotalSales DESC;
