WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS Region,
        n.n_name AS Nation,
        rs.s_name AS SupplierName,
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.SupplierRank = 1
)
SELECT 
    Region,
    Nation,
    SupplierName,
    SUM(ol.l_quantity * ol.l_extendedprice * (1 - ol.l_discount)) AS Revenue
FROM 
    TopSuppliers ts
JOIN 
    lineitem ol ON ol.l_suppkey = ts.s_suppkey
JOIN 
    orders o ON ol.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    Region, Nation, SupplierName
ORDER BY 
    Revenue DESC;
