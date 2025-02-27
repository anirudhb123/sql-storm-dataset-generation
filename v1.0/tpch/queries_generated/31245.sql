WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE o.o_orderstatus = 'O'
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales,
    MAX(p.p_retailprice) AS max_part_price,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_size > 10) AS large_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
WHERE s.s_acctbal IS NOT NULL AND 
      l.l_shipdate >= '2023-01-01' AND 
      (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY r.r_name
ORDER BY total_nations DESC, avg_supplier_balance DESC
LIMIT 10;
