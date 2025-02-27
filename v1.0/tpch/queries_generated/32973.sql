WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS recursion_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, cs.recursion_level + 1
    FROM CTE_Supplier cs
    JOIN supplier s ON cs.s_nationkey = s.s_nationkey
    WHERE cs.recursion_level < 3
)

SELECT 
    p.p_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS total_returns,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(COALESCE(s.s_acctbal, 0)) AS avg_supplier_acctbal,
    ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rn
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CTE_Supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
    OR COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_returns DESC, avg_supplier_acctbal DESC
LIMIT 10;
