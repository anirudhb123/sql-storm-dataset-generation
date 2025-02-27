WITH RECURSIVE RegionalOrders AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
    
    UNION ALL

    SELECT 
        ro.r_regionkey,
        ro.r_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_revenue
    FROM 
        RegionalOrders ro
    JOIN orders o ON ro.r_regionkey = (
        SELECT n.n_regionkey
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey IN (SELECT ps_suppkey FROM partsupp ps)
    )
    GROUP BY 
        ro.r_regionkey, ro.r_name
)

SELECT 
    r.r_regionkey,
    r.r_name,
    COALESCE(ro.total_revenue, 0) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END) AS return_revenue
FROM 
    region r
LEFT JOIN RegionalOrders ro ON r.r_regionkey = ro.r_regionkey
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 
    (ro.total_revenue IS NOT NULL OR o.o_orderstatus <> 'F')
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 0)
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_revenue DESC;
