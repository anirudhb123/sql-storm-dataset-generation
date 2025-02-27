WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_clerk, 1 AS level
    FROM orders o 
    WHERE o.o_orderstatus = 'O' 
      AND o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_clerk, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'Customer A')
    WHERE o.o_orderstatus <> 'O'
)
SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.l_discount) AS median_discount,
    MAX(COALESCE(s.s_acctbal, 0)) AS max_supplier_acctbal
FROM region r 
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE 'Asia%' 
    AND (l.l_returnflag = 'N' OR l.l_linestatus = 'O')
    AND EXISTS (
        SELECT 1 
        FROM OrderHierarchy oh 
        WHERE oh.o_orderkey = o.o_orderkey
    )
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_revenue DESC NULLS LAST;
