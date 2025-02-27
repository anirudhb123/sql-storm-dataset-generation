WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT c_nationkey FROM customer)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(l.l_quantity) AS avg_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(ps.ps_availqty) AS max_available_quantity,
    CASE 
        WHEN SUM(l.l_extendedprice) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Present'
    END AS revenue_status,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE 
    (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
    AND l.l_shipdate >= DATE '2022-01-01'
    AND l.l_shipdate < DATE '2023-01-01'
    AND o.o_orderstatus IN ('O', 'F')
    AND EXISTS (
        SELECT 1 FROM customer c 
        WHERE c.c_nationkey = p.p_partkey
    )
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 OR MAX(ps.ps_availqty) > 100
ORDER BY 
    revenue DESC;
