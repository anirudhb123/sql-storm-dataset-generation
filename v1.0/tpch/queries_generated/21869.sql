WITH regional_sales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2023-12-31' AND 
        (l.l_returnflag = 'R' OR l.l_returnflag IS NULL)
    GROUP BY 
        r.r_name
),
ranked_sales AS (
    SELECT 
        r_name,
        total_revenue,
        order_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        regional_sales
),
supplier_revenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
top_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.supplier_total
    FROM 
        supplier s
    JOIN 
        supplier_revenue sr ON s.s_suppkey = sr.s_suppkey
    WHERE 
        sr.supplier_total > (SELECT AVG(supplier_total) FROM supplier_revenue)
)
SELECT 
    r.r_name,
    COALESCE(rs.total_revenue, 0) AS regional_revenue,
    COALESCE(ts.supplier_total, 0) AS top_supplier_revenue,
    (COALESCE(rs.total_revenue, 0) - COALESCE(ts.supplier_total, 0)) AS net_revenue,
    CASE 
        WHEN COALESCE(rs.total_revenue, 0) > 1.5 * COALESCE(ts.supplier_total, 0) THEN 'High Profit'
        WHEN COALESCE(rs.total_revenue, 0) < 0.5 * COALESCE(ts.supplier_total, 0) THEN 'Low Profit'
        ELSE 'Moderate Profit' 
    END AS profit_category
FROM 
    regional_sales rs
FULL OUTER JOIN 
    top_supplier ts ON ts.supplier_total = (SELECT MAX(supplier_total) FROM supplier_revenue)
JOIN 
    region r ON r.r_name = COALESCE(rs.r_name, 'Unknown Region')
ORDER BY 
    r.r_name NULLS LAST, 
    net_revenue DESC;
