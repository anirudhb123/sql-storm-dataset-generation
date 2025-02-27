WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
top_suppliers AS (
    SELECT 
        ns.n_name,
        rt.s_name,
        rt.total_cost
    FROM 
        ranked_suppliers rt
    JOIN 
        nation ns ON rt.s_nationkey = ns.n_nationkey
    WHERE 
        rt.rank <= 5
)
SELECT 
    ns.n_name AS nation_name,
    ts.s_name AS supplier_name,
    ts.total_cost
FROM 
    top_suppliers ts
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = ns.n_name)
WHERE 
    r.r_name = 'ASIA'
ORDER BY 
    total_cost DESC;
