WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        CONCAT(p.p_name, ' - ', p.p_brand, ' - ', p.p_type) AS full_description,
        LEFT(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), 100) AS supplier_names,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_container
),

StringProcessingBenchmark AS (
    SELECT 
        r.r_name,
        STRING_AGG(DISTINCT n.n_name ORDER BY n.n_name) AS nations,
        STRING_AGG(DISTINCT c.c_name ORDER BY c.c_name) AS customers,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_comment LIKE '%special%'
    GROUP BY 
        r.r_name
)

SELECT 
    sa.p_partkey,
    sa.full_description,
    sa.supplier_names,
    spb.nations,
    spb.customers,
    spb.order_count,
    spb.total_sales
FROM 
    StringAggregation sa
JOIN 
    StringProcessingBenchmark spb ON sa.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
ORDER BY 
    sa.supplier_count DESC, spb.total_sales DESC;
