WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_nationkey, s_name, s_acctbal, NULL AS parent
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.n_nationkey, s.s_name, s.s_acctbal, sh.s_name AS parent
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal - (SELECT AVG(s_acctbal) FROM supplier)
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100)
),
order_stats AS (
    SELECT o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_tax) AS total_tax
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND GETDATE()
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, COUNT(DISTINCT ns.n_nationkey) AS nation_count,
       SUM(COALESCE(o.total_sales, 0)) AS total_sales,
       AVG(CASE WHEN p.price_rank <= 5 THEN p.p_retailprice END) AS avg_top_price,
       MAX(NULLIF(p.p_comment, 'No comment')) AS max_comment
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN ranked_parts p ON p.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_nationkey)
LEFT JOIN order_stats o ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'NATION_NAME_PLACEHOLDER')
WHERE r.r_comment LIKE '%%'
GROUP BY r.r_name
HAVING total_sales > 10000
ORDER BY nation_count DESC, total_sales ASC
OFFSET 3 ROWS FETCH NEXT 10 ROWS ONLY;
