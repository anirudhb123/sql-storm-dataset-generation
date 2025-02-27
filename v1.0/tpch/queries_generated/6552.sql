WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), national_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    r.r_name AS region,
    n.nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(total_supply_cost) AS avg_supplier_cost,
    MAX(total_cost) AS highest_part_cost
FROM 
    national_suppliers s
JOIN 
    nation n ON s.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    ranked_parts rp ON rp.total_cost = (SELECT MAX(total_cost) FROM ranked_parts)
WHERE 
    r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    r.r_name, n.nation_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    region, nation_name;
