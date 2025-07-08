WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInRegion
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        rs.s_name AS SupplierName,
        rs.TotalSupplyValue
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey))
    WHERE 
        rs.RankInRegion <= 3
)
SELECT 
    ts.RegionName,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomerCount,
    SUM(o.o_totalprice) AS TotalOrdersValue
FROM 
    TopSuppliers ts
JOIN 
    customer c ON c.c_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT rs.s_suppkey FROM RankedSuppliers rs WHERE ts.SupplierName = rs.s_name LIMIT 1))
JOIN 
    orders o ON o.o_custkey = c.c_custkey
GROUP BY 
    ts.RegionName
ORDER BY 
    TotalOrdersValue DESC;
