WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN CTE_Supplier c ON s.s_suppkey <> c.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
)
SELECT DISTINCT p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    string_agg(DISTINCT s.s_name, ', ') FILTER (WHERE s.s_acctbal IS NOT NULL) AS top_suppliers
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey AND s.s_acctbal IN (SELECT * FROM CTE_Supplier)
WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31' AND
      p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_brand LIKE '%BrandA%')
GROUP BY p.p_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
