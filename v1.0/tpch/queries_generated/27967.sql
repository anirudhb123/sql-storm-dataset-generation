WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.total_available,
    pd.avg_supply_cost,
    nd.n_name AS nation_name,
    nd.region_name,
    CONCAT('Part: ', pd.p_name, ' | Brand: ', pd.p_brand, ' | Type: ', pd.p_type, 
           ' | Total Available: ', pd.total_available, 
           ' | Avg Supply Cost: ', pd.avg_supply_cost, 
           ' | Suppliers: ', pd.supplier_names, 
           ' | Nation: ', nd.n_name, 
           ' | Region: ', nd.region_name) AS full_description
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    NationDetails nd ON s.s_nationkey = nd.n_nationkey
WHERE 
    pd.total_available > 0
ORDER BY 
    pd.avg_supply_cost DESC, 
    pd.total_available DESC;
