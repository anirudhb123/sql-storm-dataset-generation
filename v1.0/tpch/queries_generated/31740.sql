WITH RECURSIVE RegionAgg AS (
    SELECT n_regionkey, SUM(s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n_regionkey
    HAVING SUM(s_acctbal) > 100000
    UNION ALL
    SELECT r.r_regionkey, SUM(s.s_acctbal)
    FROM region r
    JOIN supplier s ON r.r_regionkey = n.n_regionkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE r.r_regionkey IS NOT NULL
)
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(l.l_discount) AS avg_discount,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY AVG(l.l_extendedprice) DESC) AS rank
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
 LEFT JOIN RegionAgg ra ON ra.n_regionkey = s.s_nationkey
WHERE p.p_retailprice > 20.00
AND (ra.total_acctbal IS NULL OR ra.total_acctbal < 50000)
AND EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.o_orderkey = l.l_orderkey 
    AND o.o_orderstatus = 'F'
)
GROUP BY p.p_partkey, p.p_name, p.p_type
HAVING COUNT(DISTINCT l.l_linenumber) > 5
ORDER BY rank, total_returned DESC
LIMIT 10;
