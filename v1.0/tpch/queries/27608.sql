WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        COUNT(ps.ps_availqty) AS available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(p.p_retailprice) AS avg_retail_price,
        STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
RegionSummary AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.available_quantity,
    sp.total_supply_cost,
    sp.avg_retail_price,
    sp.part_comments,
    rs.nation_name,
    rs.region_name,
    rs.supplier_count,
    rs.supplier_comments
FROM 
    SupplierParts sp
JOIN 
    RegionSummary rs ON sp.supplier_name LIKE '%' || rs.nation_name || '%'
ORDER BY 
    sp.total_supply_cost DESC, sp.part_name;
