WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_list
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
    ps.p_partkey,
    ps.p_name,
    ps.p_brand,
    ps.p_retailprice,
    ps.supplier_count,
    ps.avg_supply_cost,
    ns.region_name,
    ns.total_suppliers,
    ns.supplier_list
FROM 
    PartStats ps
JOIN 
    NationStats ns ON ps.supplier_count = ns.total_suppliers
WHERE 
    ps.avg_supply_cost < (SELECT AVG(ps_avg.ps_supplycost) FROM partsupp ps_avg)
ORDER BY 
    ps.p_retailprice DESC
LIMIT 10;
