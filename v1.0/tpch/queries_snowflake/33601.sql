
WITH RECURSIVE supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN supplier_data sd ON s.s_suppkey = sd.s_suppkey
    WHERE s.s_acctbal < sd.s_acctbal * 0.5
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(li.l_linenumber) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01' 
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000
)
SELECT 
    s.s_suppkey,
    s.s_name,
    o.total_revenue,
    o.customer_count,
    CASE 
        WHEN o.item_count > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    COALESCE(r.r_name, 'Unknown Region') AS region,
    sd.nation_name
FROM supplier s
LEFT JOIN order_summary o ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size BETWEEN 4 AND 10)) 
LEFT JOIN region r ON EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = s.s_nationkey AND n.n_regionkey = r.r_regionkey)
JOIN supplier_data sd ON s.s_suppkey = sd.s_suppkey
WHERE o.total_revenue IS NOT NULL
ORDER BY o.total_revenue DESC, s.s_name ASC
LIMIT 100;
