WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.TotalSupplyValue,
        n.n_name AS NationName
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rs.s_suppkey LIMIT 1)
    WHERE 
        rs.SupplierRank <= 5
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderValue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ts.NationName,
    COUNT(DISTINCT to.OrderValue) AS DistinctOrderCount,
    SUM(ts.TotalSupplyValue) AS TotalSupplyValueByNation
FROM 
    TopSuppliers ts
JOIN 
    TotalOrderValue to ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = to.o_orderkey LIMIT 1)
GROUP BY 
    ts.NationName
ORDER BY 
    TotalSupplyValueByNation DESC;
