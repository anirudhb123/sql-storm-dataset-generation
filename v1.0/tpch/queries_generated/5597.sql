WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS Region, 
        n.n_name AS Nation, 
        rs.s_name AS SupplierName, 
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS OrderCount, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    hcs.Region, 
    hcs.Nation, 
    hcs.SupplierName, 
    co.c_name AS CustomerName, 
    co.OrderCount, 
    co.TotalSpent 
FROM 
    HighCostSuppliers hcs
JOIN 
    CustomerOrders co ON hcs.TotalSupplyCost > co.TotalSpent 
ORDER BY 
    hcs.Region, hcs.Nation, hcs.TotalSupplyCost DESC, co.TotalSpent DESC;
