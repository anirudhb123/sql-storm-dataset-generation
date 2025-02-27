WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    sd.region_name,
    sd.nation_name,
    STRING_AGG(sd.s_name || ' (Cost: ' || sd.total_supplycost || ')', ', ') AS top_suppliers
FROM 
    SupplierDetails sd
GROUP BY 
    sd.region_name, sd.nation_name
ORDER BY 
    sd.region_name, sd.nation_name;
