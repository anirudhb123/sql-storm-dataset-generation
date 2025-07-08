
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        t.nation_name,
        t.s_name,
        t.part_count,
        t.total_supply_value
    FROM 
        RankedSuppliers t
    JOIN 
        nation n ON t.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.rn <= 3
)
SELECT 
    region_name,
    nation_name,
    LISTAGG(s_name || ' (Parts: ' || part_count || ', Total Value: ' || total_supply_value || ')', '; ') AS top_suppliers
FROM 
    TopSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
