WITH RECURSIVE SupplierDepth AS (
    SELECT s.s_suppkey, s.s_name, NULL::integer AS parent_key, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT ss.s_suppkey, ss.s_name, sd.s_suppkey AS parent_key, sd.depth + 1
    FROM supplier ss
    JOIN SupplierDepth sd ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1' LIMIT 1) LIMIT 1)
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_sales,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY total_sales DESC) AS sales_rank
FROM nation n
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierDepth sd ON sd.s_suppkey = s.s_suppkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_sales DESC
LIMIT 10;
