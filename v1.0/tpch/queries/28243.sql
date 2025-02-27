WITH PartAggregates AS (
    SELECT 
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(p.p_retailprice) AS average_retail_price,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_brand, p.p_type
), RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    pa.p_brand,
    pa.p_type,
    pa.supplier_count,
    pa.total_available_quantity,
    pa.total_supply_cost,
    pa.average_retail_price,
    pa.supplier_names,
    rs.region_name,
    rs.nation_count,
    rs.nation_names
FROM 
    PartAggregates pa
CROSS JOIN 
    RegionSummary rs
WHERE 
    pa.supplier_count > 5 AND 
    pa.average_retail_price < (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    pa.total_available_quantity DESC, 
    pa.average_retail_price ASC;
