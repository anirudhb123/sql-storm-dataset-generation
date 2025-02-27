WITH PartCounts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_brand,
        COUNT(ps.ps_supplycost) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    pc.p_partkey,
    pc.p_name,
    pc.p_brand,
    pc.supplier_count AS part_supplier_count,
    pc.total_supply_cost,
    pc.avg_supply_cost,
    ni.n_name AS nation_name,
    ni.region_name,
    ni.supplier_count AS nation_supplier_count,
    ni.total_acctbal
FROM 
    PartCounts pc
JOIN 
    NationsInfo ni ON pc.supplier_count = ni.nation_supplier_count
WHERE 
    pc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartCounts)
ORDER BY 
    pc.avg_supply_cost DESC, ni.total_acctbal DESC;
