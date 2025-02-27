WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopNationSuppliers AS (
    SELECT 
        n.n_name,
        COUNT(*) AS supplier_count,
        SUM(rs.total_supply_cost) AS total_nation_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.supply_rank <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    t.n_name,
    t.supplier_count,
    t.total_nation_supply_cost,
    p.p_brand,
    p.p_type,
    p.p_size,
    AVG(l.l_extendedprice) AS avg_price_per_part
FROM 
    TopNationSuppliers t
JOIN 
    supplier s ON s.s_nationkey = t.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    t.n_name, t.supplier_count, t.total_nation_supply_cost, p.p_brand, p.p_type, p.p_size
HAVING 
    t.total_nation_supply_cost > 100000
ORDER BY 
    t.total_nation_supply_cost DESC, t.n_name ASC;
