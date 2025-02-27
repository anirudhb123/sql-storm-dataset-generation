WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
best_suppliers AS (
    SELECT 
        r.r_name AS region, 
        n.n_name AS nation, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        ranked_suppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    b.region,
    b.nation,
    COUNT(DISTINCT b.s_suppkey) AS number_of_best_suppliers,
    SUM(b.total_supply_cost) AS total_cost_of_best_suppliers
FROM 
    best_suppliers b
GROUP BY 
    b.region, b.nation
ORDER BY 
    b.region, b.nation;
