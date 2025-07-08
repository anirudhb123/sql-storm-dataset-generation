
WITH RECURSIVE supplier_tree AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           s.s_comment, st.level + 1
    FROM supplier s
    JOIN supplier_tree st ON s.s_nationkey = st.s_suppkey
)
SELECT p.p_partkey, p.p_name, p.p_retailprice,
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
       SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales,
       LISTAGG(CASE WHEN l.l_returnflag = 'R' THEN l.l_comment END, ', ') WITHIN GROUP (ORDER BY l.l_comment) AS return_comments
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_tree st ON ps.ps_suppkey = st.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE p.p_size BETWEEN 1 AND 30
  AND (st.level IS NULL OR st.level <= 2)
  AND EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.o_orderkey = l.l_orderkey
        AND o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderstatus IN ('O', 'F')
  )
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING SUM(ps.ps_availqty) > 100
   AND MAX(p.p_retailprice) BETWEEN 10.00 AND 100.00
ORDER BY supplier_count DESC, discounted_sales DESC
LIMIT 50;
