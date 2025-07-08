
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 50000
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > 50000 AND 
        sh.level < 3
)
SELECT 
    n.n_name, 
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
    AVG(l.l_quantity) AS avg_line_quantity,
    LISTAGG(DISTINCT CONCAT(p.p_name, ' (', p.p_mfgr, ')'), ', ') AS part_names
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate < DATE '1998-01-01' AND 
    (l.l_returnflag = 'R' OR l.l_returnflag IS NULL)
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000 AND 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_revenue DESC;
