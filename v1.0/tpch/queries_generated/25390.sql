WITH StringStats AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        LENGTH(p.p_comment) AS part_comment_length,
        LENGTH(s.s_comment) AS supplier_comment_length,
        LENGTH(c.c_comment) AS customer_comment_length,
        COALESCE(NULLIF(CHARINDEX('urgent', l.l_comment), 0), 0) AS has_urgent,
        o.o_orderstatus AS order_status
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        LENGTH(p.p_name) > 10
        AND s.s_acctbal > 0
        AND o.o_totalprice > 100
),
AggregatedStats AS (
    SELECT 
        AVG(part_comment_length) AS avg_part_comment_length,
        AVG(supplier_comment_length) AS avg_supplier_comment_length,
        AVG(customer_comment_length) AS avg_customer_comment_length,
        SUM(has_urgent) AS total_urgent_comments,
        COUNT(DISTINCT customer_name) AS unique_customers,
        COUNT(DISTINCT part_name) AS unique_parts
    FROM 
        StringStats
)
SELECT 
    * 
FROM 
    AggregatedStats;
