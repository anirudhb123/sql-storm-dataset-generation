WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    COALESCE(NULLIF(r.r_name, ''), 'UNKNOWN') AS region_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    NationHierarchy nh ON c.c_nationkey = nh.n_nationkey
LEFT JOIN 
    region r ON nh.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '2023-01-01' 
    AND o.o_orderdate < '2023-10-01'
    AND l.l_returnflag = 'R'
GROUP BY 
    c.c_custkey, c.c_name, c.c_nationkey, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC
LIMIT 100;
