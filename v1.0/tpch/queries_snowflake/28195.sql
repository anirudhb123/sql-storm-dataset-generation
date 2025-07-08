
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
), 
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierDetails
)
SELECT 
    s.s_suppkey AS suppkey,
    s.s_name AS name,
    s.region_name,
    s.part_count,
    s.total_supply_cost,
    s.supplied_parts
FROM 
    TopSuppliers s
WHERE 
    s.supplier_rank <= 10
ORDER BY 
    s.total_supply_cost DESC;
