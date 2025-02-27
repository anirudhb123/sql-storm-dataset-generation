WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
top_suppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        ranked_suppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
)
SELECT 
    r_name,
    STRING_AGG(CONCAT(s_name, ' (', total_supply_cost, ')'), ', ') AS top_suppliers_list
FROM 
    top_suppliers
GROUP BY 
    r_name
ORDER BY 
    r_name;
