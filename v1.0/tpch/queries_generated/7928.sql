WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalValue,
        COUNT(DISTINCT p.p_partkey) AS PartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS CustomerCount
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
)
SELECT 
    rs.s_name AS SupplierName,
    rs.TotalValue AS SupplierTotalValue,
    co.c_name AS CustomerName,
    co.OrderCount AS CustomerOrderCount,
    co.TotalSpent AS CustomerTotalSpent,
    rn.r_name AS RegionName,
    rn.n_name AS NationName,
    rn.CustomerCount AS RegionCustomerCount
FROM 
    SupplierStats rs
JOIN 
    CustomerOrders co ON rs.PartsSupplied > 5
JOIN 
    RegionNation rn ON rn.CustomerCount > 10
WHERE 
    rs.TotalValue > 100000
ORDER BY 
    rs.TotalValue DESC, co.TotalSpent DESC;
