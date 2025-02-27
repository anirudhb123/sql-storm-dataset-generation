WITH supplier_part_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
nation_sales AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
part_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
ranked_sales AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ps.total_revenue,
        ROW_NUMBER() OVER (ORDER BY ps.total_revenue DESC) AS revenue_rank
    FROM 
        part_sales ps
    WHERE 
        ps.total_revenue > 1000
)
SELECT 
    s.s_name,
    s.total_available,
    s.avg_supply_cost,
    ns.total_sales,
    rs.p_name,
    rs.total_revenue,
    rs.revenue_rank
FROM 
    supplier_part_stats s
LEFT JOIN 
    nation_sales ns ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM ranked_sales rs))
LEFT JOIN 
    ranked_sales rs ON s.total_parts > 5 AND rs.total_revenue > 500
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    s.avg_supply_cost DESC, rs.total_revenue DESC;
