WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(rs.TotalCost) AS RegionTotalCost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
    WHERE 
        rs.SupplierRank <= 5
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    t.r_regionkey,
    t.r_name,
    t.RegionTotalCost,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    AVG(o.o_totalprice) AS AvgOrderValue
FROM 
    TopSuppliers t
JOIN 
    customer c ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = t.r_regionkey)
JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    t.r_regionkey, t.r_name, t.RegionTotalCost
ORDER BY 
    t.RegionTotalCost DESC, AvgOrderValue;
