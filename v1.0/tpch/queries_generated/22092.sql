WITH RECURSIVE supplier_tree AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, st.level + 1
    FROM supplier s
    JOIN supplier_tree st ON s.s_suppkey = st.s_suppkey
    WHERE s.s_acctbal > (SELECT MAX(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey) 
    OR st.level < 3
), 
filtered_parts AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_availqty, MAX(p.p_retailprice) AS max_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 25
    GROUP BY p.p_partkey 
    HAVING SUM(ps.ps_availqty) < (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
), 
order_stats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'P') 
    AND l.l_shipdate < (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY o.o_orderkey
)
SELECT 
    CASE 
        WHEN st.level = 0 THEN 'Top Supplier'
        WHEN st.level = 1 THEN 'Mid Supplier'
        ELSE 'Entry Supplier' 
    END AS supplier_level,
    st.s_name,
    st.s_acctbal,
    fp.total_availqty,
    fp.max_price,
    os.line_count,
    os.total_revenue,
    COALESCE(subquery.r_name, 'Unknown Region') AS region_name
FROM supplier_tree st
LEFT JOIN filtered_parts fp ON fp.p_partkey = 
    (SELECT TOP 1 p_partkey FROM filtered_parts ORDER BY RANDOM())
LEFT JOIN (
    SELECT n.n_nationkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_nationkey IS NOT NULL
) subquery ON st.s_nationkey = subquery.n_nationkey
JOIN order_stats os ON os.o_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE NOT EXISTS (
        SELECT 1 FROM lineitem l WHERE l.l_orderkey = orders.o_orderkey AND l.l_returnflag = 'R'
    )
    UNION
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_tax > 0 AND l.l_discount < 0.2
)
ORDER BY st.s_acctbal DESC NULLS LAST;
