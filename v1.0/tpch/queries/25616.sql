
WITH StringAggregation AS (
    SELECT 
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY p.p_brand
),

EnhancedRegionInfo AS (
    SELECT 
        r.r_name,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations,
        STRING_AGG(DISTINCT p.p_type, ', ') AS product_types,
        SUM(s.s_acctbal) AS total_supplier_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN part p ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
    GROUP BY r.r_name
)

SELECT 
    s.p_brand AS brand_stats,
    r.r_name AS region_info
FROM (
    SELECT 
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_brand
) AS s 
JOIN (
    SELECT 
        r.r_name,
        SUM(s.s_acctbal) AS total_supplier_acctbal,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
) AS r ON s.supplier_count > r.total_supplier_acctbal
ORDER BY s.p_brand;
