WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_ordered
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    s.s_name,
    ps.p_name,
    rs.total_supply_cost,
    pp.total_ordered
FROM 
    RankedSuppliers rs
JOIN 
    PopularParts pp ON pp.total_ordered > 500
JOIN 
    partsupp ps ON ps.ps_partkey = pp.p_partkey
WHERE 
    rs.rank <= 3
ORDER BY 
    rs.total_supply_cost DESC, pp.total_ordered DESC;
