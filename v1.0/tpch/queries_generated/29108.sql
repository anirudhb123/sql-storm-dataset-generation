WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(CASE WHEN ps.ps_availqty > 100 THEN 'High Availability' ELSE 'Low Availability' END) AS availability_status
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
final_benchmark AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ns.n_name AS supplier_nation,
        ps.total_available,
        ps.avg_supply_cost,
        ns.supplier_count,
        ns.supplier_names,
        ps.availability_status
    FROM 
        part_summary ps
    JOIN 
        supplier s ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey)
    JOIN 
        nation_summary ns ON s.s_nationkey = ns.n_nationkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.supplier_nation,
    f.total_available,
    f.avg_supply_cost,
    f.supplier_count,
    f.supplier_names,
    f.availability_status
FROM 
    final_benchmark f
WHERE 
    f.avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp) AND 
    f.total_available > 50
ORDER BY 
    f.total_available DESC, f.avg_supply_cost ASC;
