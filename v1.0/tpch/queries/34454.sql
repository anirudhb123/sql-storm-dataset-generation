WITH RECURSIVE OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_shippriority, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_shippriority,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    JOIN OrderCTE ocas ON o.o_orderkey = ocas.o_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(n.n_name, 'UNKNOWN') as nation_name,
    r.r_name as region_name,
    CASE 
        WHEN AVG(s.s_acctbal) IS NULL THEN 'No balance'
        ELSE CONCAT('$', ROUND(AVG(s.s_acctbal), 2))
    END AS avg_supplier_acctbal
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN customer c ON c.c_custkey = (SELECT c2.c_custkey 
                                    FROM customer c2 
                                    JOIN orders o ON o.o_custkey = c2.c_custkey 
                                    WHERE o.o_orderkey = l.l_orderkey 
                                    LIMIT 1)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate >= '1997-01-01' 
      AND l.l_shipdate < '1997-12-31'
      AND p.p_retailprice > 20.00
GROUP BY p.p_partkey, p.p_name, n.n_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l2.l_extendedprice) 
                                                       FROM lineitem l2 
                                                       JOIN orders o2 ON l2.l_orderkey = o2.o_orderkey)
ORDER BY revenue DESC
FETCH FIRST 10 ROWS ONLY;