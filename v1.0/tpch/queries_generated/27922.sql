WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LENGTH(s.s_comment) AS comment_length,
        LOWER(s.s_name) AS lower_supplier_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
part_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_size < 25
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    si.nation_name,
    si.region_name,
    COUNT(DISTINCT si.s_suppkey) AS supplier_count,
    COUNT(DISTINCT pi.p_partkey) AS part_count,
    AVG(pi.comment_length) AS avg_part_comment_length,
    AVG(si.comment_length) AS avg_supplier_comment_length,
    SUM(os.total_revenue) AS total_revenue_per_order
FROM supplier_info si
JOIN part_info pi ON si.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = pi.p_partkey
)
JOIN order_summary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = si.n_suppkey
    )
)
GROUP BY si.nation_name, si.region_name
ORDER BY total_revenue_per_order DESC, supplier_count ASC;
