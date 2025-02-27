WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_name = 'GERMANY'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END), 0) AS total_returned,
    ROUND(AVG(CASE 
        WHEN ps.ps_supplycost IS NULL THEN NULL
        ELSE ps.ps_supplycost / NULLIF(p.p_retailprice, 0) 
    END), 2) AS avg_supply_to_retail_ratio,
    DENSE_RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank,
    CASE
        WHEN MAX(o.o_orderstatus) = 'F' THEN 'Fully Filled'
        WHEN MAX(o.o_orderstatus) IS NULL THEN 'No Orders'
        ELSE 'Partially Filled'
    END AS order_status_summary
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
INNER JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation_hierarchy nh ON c.c_nationkey = nh.n_nationkey
WHERE (p.p_retailprice > 20 AND p.p_size < 15) 
   OR (p.p_type LIKE 'type%' AND p.p_container IS NOT NULL)
   AND (s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey))
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_returned DESC, p.p_name
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
