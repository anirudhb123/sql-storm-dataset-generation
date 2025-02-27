WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_total_price,
    MAX(l.l_tax) AS max_tax,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ')'), ', ') AS part_names,
    CASE 
        WHEN MAX(o.o_orderstatus) IS NULL THEN 'No Orders'
        ELSE MAX(o.o_orderstatus)
    END AS order_status
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND l.l_returnflag = 'N'
    AND (p.p_size IS NOT NULL OR p.p_container IS NOT NULL)
GROUP BY 
    n.n_name
ORDER BY 
    total_quantity DESC
FETCH FIRST 10 ROWS ONLY;
