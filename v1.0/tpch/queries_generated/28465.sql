WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationDetails AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(r.total_supplycost) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers r ON n.n_nationkey = r.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    nd.n_name,
    nd.supplier_count,
    nd.total_revenue,
    (SELECT 
        STRING_AGG(s.s_name, ', ') 
     FROM 
        supplier s 
     JOIN 
        RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey 
     WHERE 
        rs.rn <= 3 AND rs.s_nationkey = nd.n_nationkey
    ) AS top_suppliers
FROM 
    NationDetails nd
ORDER BY 
    nd.total_revenue DESC;
