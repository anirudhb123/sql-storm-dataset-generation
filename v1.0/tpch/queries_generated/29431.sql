WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        p.p_brand, 
        COUNT(ps.ps_availqty) AS availability_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, p.p_brand
),
RegionNationDetails AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    p.p_partkey,
    p.p_name AS part_name,
    p.supplier_name,
    p.p_brand,
    p.availability_count,
    p.total_supply_cost,
    p.supplier_comments,
    r.nation_name,
    r.region_name,
    r.supplier_count
FROM 
    PartSupplierDetails p
JOIN 
    RegionNationDetails r ON p.supplier_name LIKE '%' || r.nation_name || '%'
WHERE 
    p.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartSupplierDetails)
ORDER BY 
    p.total_supply_cost DESC;
