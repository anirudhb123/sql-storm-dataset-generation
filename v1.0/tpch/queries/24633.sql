
WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '1995-01-01' AND '1996-01-01'
    GROUP BY 
        n.n_name
    
    UNION ALL
    
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1998-10-01 12:34:56'
        AND n.n_name NOT IN (SELECT n_name FROM nation_sales)
    GROUP BY 
        n.n_name
),
ranked_sales AS (
    SELECT 
        n_name, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        nation_sales
),
top_sales AS (
    SELECT 
        n_name,
        total_revenue,
        revenue_rank
    FROM 
        ranked_sales
    WHERE 
        revenue_rank <= 5 OR revenue_rank IS NULL
)
SELECT 
    t.n_name, 
    COALESCE(t.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN t.revenue_rank IS NOT NULL THEN 'Top Performer'
        ELSE 'Non Performer'
    END AS performance_status,
    (SELECT COUNT(*) FROM lineitem WHERE l_returnflag = 'R' AND l_tax > 0.05) AS returns_count,
    (SELECT AVG(s.s_acctbal) 
     FROM supplier s 
     JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
     WHERE ps.ps_availqty <= (SELECT MAX(ps_availqty) FROM partsupp)) AS avg_supplier_balance
FROM 
    top_sales t
LEFT JOIN 
    region r ON t.n_name LIKE '%' || r.r_name || '%'
WHERE 
    r.r_comment IS NOT NULL
ORDER BY 
    total_revenue DESC;
