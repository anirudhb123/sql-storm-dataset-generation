WITH StringAggregations AS (
    SELECT 
        p.p_partkey,
        SUM(LENGTH(p.p_name)) AS total_name_length,
        COUNT(DISTINCT p.p_brand) AS unique_brands,
        MAX(LENGTH(p.p_comment)) AS max_comment_length,
        GROUP_CONCAT(DISTINCT p.p_type ORDER BY p.p_type ASC SEPARATOR ', ') AS type_list
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
    WHERE 
        r.r_name LIKE '%East%'
    GROUP BY 
        p.p_partkey
),
CustomerData AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(LENGTH(c.c_comment)) AS avg_comment_length
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_name
)
SELECT 
    sa.p_partkey,
    sa.total_name_length,
    sa.unique_brands,
    sa.max_comment_length,
    sa.type_list,
    cd.c_name,
    cd.total_spent,
    cd.total_orders,
    cd.avg_comment_length
FROM 
    StringAggregations sa
JOIN 
    CustomerData cd ON sa.total_name_length > cd.avg_comment_length
ORDER BY 
    sa.total_name_length DESC, 
    cd.total_spent DESC
LIMIT 
    100;
