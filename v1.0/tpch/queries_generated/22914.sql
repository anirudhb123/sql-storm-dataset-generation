WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
    UNION ALL
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        ns.total_orders + COUNT(DISTINCT o.o_orderkey),
        ns.total_revenue + SUM(l.l_extendedprice * (1 - l.l_discount))
    FROM 
        nation_sales ns
    JOIN 
        nation n ON n.n_nationkey = ns.n_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
),
ranked_sales AS (
    SELECT 
        n.n_name, 
        ns.total_orders, 
        ns.total_revenue,
        RANK() OVER (ORDER BY ns.total_revenue DESC) AS revenue_rank
    FROM 
        nation_sales ns
    JOIN 
        nation n ON ns.n_nationkey = n.n_nationkey
)
SELECT 
    rs.n_name,
    COALESCE(rs.total_orders, 0) AS total_orders,
    ROUND(COALESCE(rs.total_revenue, 0), 2) AS total_revenue,
    CASE 
        WHEN rs.revenue_rank <= 10 THEN 'Top 10'
        WHEN rs.revenue_rank BETWEEN 11 AND 20 THEN 'Top 20'
        ELSE 'Other'
    END AS revenue_category
FROM 
    ranked_sales rs
UNION 
SELECT 
    'Unknown' AS n_name,
    0 AS total_orders,
    0.00 AS total_revenue,
    'No Revenue' AS revenue_category
WHERE 
    NOT EXISTS (SELECT 1 FROM ranked_sales)
ORDER BY 
    total_revenue DESC
LIMIT 50;
