
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, n.n_regionkey
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        rs.part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    sd.region_name,
    LISTAGG(sd.s_name, ', ') WITHIN GROUP (ORDER BY sd.s_name) AS top_suppliers,
    SUM(sd.part_count) AS total_parts_supplied
FROM 
    SupplierDetails sd
GROUP BY 
    sd.region_name
ORDER BY 
    sd.region_name;
