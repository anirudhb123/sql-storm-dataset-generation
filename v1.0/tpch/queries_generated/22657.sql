WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), ordered_revenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY c.c_custkey, c.c_nationkey
), part_details AS (
    SELECT 
        p.p_partkey, 
        p.p_brand, 
        SUM(ps.ps_availqty * p.p_retailprice) AS total_value,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand
)
SELECT 
    nh.n_name AS nation_name,
    COALESCE(o.total_revenue, 0) AS total_revenue,
    COALESCE(pd.total_value, 0) AS part_value,
    pd.supplier_count,
    CASE 
        WHEN o.revenue_rank = 1 THEN 'Top'
        WHEN o.revenue_rank IS NULL THEN 'No Revenue'
        ELSE 'Other'
    END AS revenue_category
FROM nation_hierarchy nh
LEFT JOIN ordered_revenue o ON nh.n_nationkey = o.c_custkey
LEFT JOIN part_details pd ON pd.supplier_count = (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s WHERE s.s_nationkey = nh.n_nationkey)
WHERE pd.total_value > 10000
OR o.total_revenue IS NULL
ORDER BY nh.n_name, total_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
