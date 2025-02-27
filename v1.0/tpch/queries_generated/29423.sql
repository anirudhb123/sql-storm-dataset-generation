WITH String_Analysis AS (
    SELECT 
        p.p_name AS part_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_uppercase,
        LOWER(p.p_name) AS name_lowercase,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS comment_excerpt,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_comment, r.r_name, n.n_name, s.s_name, c.c_name
),
String_Stats AS (
    SELECT 
        MAX(name_length) AS max_length,
        MIN(name_length) AS min_length,
        AVG(name_length) AS avg_length,
        COUNT(*) AS total_parts
    FROM 
        String_Analysis
)
SELECT 
    sa.part_name,
    sa.name_length,
    sa.name_uppercase,
    sa.name_lowercase,
    sa.comment_excerpt,
    sa.region_name,
    sa.nation_name,
    sa.supplier_name,
    sa.customer_name,
    sa.order_count,
    ss.max_length,
    ss.min_length,
    ss.avg_length,
    ss.total_parts
FROM 
    String_Analysis sa
CROSS JOIN 
    String_Stats ss
ORDER BY 
    sa.name_length DESC;
