WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(SUBSTRING(s.s_name, 1, 3), '...', ' supplies ', SUBSTRING(p.p_name, 1, 10), '...', ' with availability of ', CAST(ps.ps_availqty AS CHAR)) AS description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 50
),
RegionNations AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    rp.supplier_name,
    rp.part_name,
    rp.available_quantity,
    rp.supply_cost,
    rp.description,
    rn.region_name,
    rn.nation_name,
    rn.supplier_count
FROM 
    SupplierParts rp
JOIN 
    RegionNations rn ON rp.supplier_name LIKE CONCAT('%', rn.nation_name, '%')
ORDER BY 
    rn.region_name, rp.available_quantity DESC;
