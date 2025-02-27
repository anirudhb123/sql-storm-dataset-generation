WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
MaxCostSuppliers AS (
    SELECT 
        r.r_name,
        SUM(rs.total_cost) AS max_total_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.nation_name)
    WHERE 
        rs.cost_rank = 1
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    m.max_total_cost
FROM 
    MaxCostSuppliers m
JOIN 
    region r ON r.r_name = m.r_name
WHERE 
    m.max_total_cost > (SELECT AVG(max_total_cost) FROM MaxCostSuppliers)
ORDER BY 
    m.max_total_cost DESC;
