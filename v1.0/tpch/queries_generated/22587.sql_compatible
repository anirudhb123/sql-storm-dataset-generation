
WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
    WHERE nh.level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM SupplierStats s
    WHERE s.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierStats)
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE 
        WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE l.l_extendedprice 
    END) AS total_revenue,
    COUNT(CASE 
        WHEN l.l_returnflag = 'R' THEN 1 
        END) AS return_count,
    NULLIF(MAX(l.l_quantity), 0) AS max_quantity,
    COALESCE(STRING_AGG(DISTINCT p.p_name, ', ' ORDER BY p.p_name), 'No parts') AS part_names
FROM nation n
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
CROSS JOIN part p
LEFT JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%West%')
  AND (l.l_discount IS NULL OR l.l_discount < 0.05)
  AND COALESCE(o.o_totalprice, 0) > 1000
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 1
ORDER BY total_revenue DESC, customer_count DESC;
