WITH SupplierCounts AS (
    SELECT 
        s.n_nationkey,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.n_nationkey
), 
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    SUM(tc.total_revenue) AS total_revenue,
    AVG(tc.total_returned) AS avg_returned,
    COUNT(DISTINCT s.s_suppkey) AS distinct_supplier_count,
    COUNT(DISTINCT ot.o_orderkey) AS distinct_order_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierCounts sc ON n.n_nationkey = sc.n_nationkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopProducts tc ON s.s_suppkey = (SELECT ps.ps_suppkey
                                       FROM partsupp ps
                                       WHERE ps.ps_partkey = tc.p_partkey
                                       ORDER BY ps.ps_supplycost ASC
                                       LIMIT 1)
LEFT JOIN 
    orders ot ON s.s_suppkey = ot.o_custkey
WHERE 
    r.r_name IS NOT NULL 
    AND (sc.supplier_count IS NULL OR sc.supplier_count > 5)
GROUP BY 
    r.r_name
HAVING 
    SUM(tc.total_revenue) > 100000
ORDER BY 
    total_revenue DESC;
