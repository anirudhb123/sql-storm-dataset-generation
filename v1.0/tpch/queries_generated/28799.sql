WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(r.total_supply_cost) AS nation_total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(r.total_supply_cost) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        RankedSuppliers r ON n.n_nationkey = r.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    t.nation_rank,
    t.n_name,
    s.s_name,
    r.total_supply_cost
FROM 
    TopNations t
JOIN 
    RankedSuppliers s ON t.n_nationkey = s.s_nationkey
WHERE 
    s.supplier_rank <= 3
ORDER BY 
    t.nation_rank, s.total_supply_cost DESC;
