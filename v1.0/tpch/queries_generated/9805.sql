WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
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
        p.p_name,
        rp.total_cost
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
    JOIN 
        nation np ON s.s_nationkey = np.n_nationkey
    JOIN 
        region r ON np.n_regionkey = r.r_regionkey
    WHERE 
        rp.cost_rank <= 10
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    p.p_name AS part_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue
FROM 
    HighCostParts hcp
JOIN 
    lineitem lp ON lp.l_partkey = hcp.p_partkey
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
GROUP BY 
    r.r_name, n.n_name, p.p_name
ORDER BY 
    revenue DESC, region, nation, part_name;
