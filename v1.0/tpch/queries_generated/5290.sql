WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
region_totals AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(rs.total_cost) AS region_total_cost
    FROM 
        region r
    JOIN 
        ranked_suppliers rs ON rs.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rt.r_name,
    rt.region_total_cost,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM 
    region_totals rt
LEFT JOIN 
    nation n ON rt.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON s.s_suppkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    rt.region_total_cost > (SELECT AVG(region_total_cost) FROM region_totals)
GROUP BY 
    rt.r_name, rt.region_total_cost
ORDER BY 
    rt.region_total_cost DESC;
