WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
),
HighCostParts AS (
    SELECT 
        r.r_name,
        np.n_name,
        rp.p_name,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.p_partkey = s.s_suppkey
    JOIN 
        nation np ON s.s_nationkey = np.n_nationkey
    JOIN 
        region r ON np.n_regionkey = r.r_regionkey
    WHERE 
        rp.rank <= 10
)
SELECT 
    r.r_name AS region,
    np.n_name AS nation,
    ARRAY_AGG(rp.p_name) AS top_parts,
    SUM(rp.total_supply_cost) AS summed_supply_cost
FROM 
    HighCostParts rp
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rp.p_partkey))
JOIN 
    nation np ON np.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rp.p_partkey)
GROUP BY 
    r.r_name, np.n_name
ORDER BY 
    summed_supply_cost DESC
LIMIT 5;
