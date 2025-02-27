WITH StringAggregation AS (
    SELECT 
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE p.p_size > 10
    GROUP BY p.p_brand, p.p_type
),
RegionDetails AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    sa.p_brand,
    sa.p_type,
    sa.supplier_count,
    sa.supplier_names,
    rd.r_name,
    rd.nation_count,
    rd.nations
FROM StringAggregation sa
JOIN RegionDetails rd ON sa.supplier_count > 0
ORDER BY sa.p_brand, sa.p_type, rd.r_name;
