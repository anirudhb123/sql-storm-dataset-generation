WITH RECURSIVE MaterialHierarchy AS (
    SELECT 
        p_partkey,
        p_name,
        p_container,
        p_size,
        1 AS level
    FROM 
        part
    WHERE 
        p_size < 10
    UNION ALL
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_container,
        p.p_size,
        mh.level + 1
    FROM 
        part p
    JOIN 
        MaterialHierarchy mh ON p.p_size < mh.p_size
)
SELECT 
    n.n_name,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty,
    SUM(COALESCE(ps.ps_supplycost, 0) * COALESCE(l.l_quantity, 0)) AS total_cost,
    AVG(l.l_discount) OVER (PARTITION BY n.n_name) AS avg_discount,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    CASE WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 'Has Customers' ELSE 'No Customers' END AS customer_status
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    (l.l_shipdate IS NOT NULL AND l.l_shipdate >= '2023-01-01')
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_cost DESC
LIMIT 10;
