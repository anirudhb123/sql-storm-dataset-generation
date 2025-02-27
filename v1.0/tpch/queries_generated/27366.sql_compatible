
WITH regex_parts AS (
    SELECT 
        p_partkey,
        p_name,
        REGEXP_REPLACE(p_name, '([A-Z])', '\\1') AS processed_name,
        LENGTH(p_name) AS original_length,
        LENGTH(REGEXP_REPLACE(p_name, '([A-Z])', '\\1')) AS processed_length
    FROM 
        part
),
region_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        CONCAT(s.s_name, ' from ', r.r_name) AS full_supplier_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
benchmark_results AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(LENGTH(p.p_name)) AS avg_part_name_length,
        SUM(os.total_revenue) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        regex_parts p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        order_summary os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = s.s_suppkey LIMIT 1)
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    part_count,
    avg_part_name_length,
    total_revenue
FROM 
    benchmark_results
ORDER BY 
    total_revenue DESC;
