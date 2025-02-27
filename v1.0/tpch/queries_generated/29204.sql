WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_comment,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    sd.s_name,
    COUNT(DISTINCT pi.p_partkey) AS distinct_parts,
    SUM(c.total_spent) AS total_revenue,
    MAX(pi.comment_length) AS longest_comment_length,
    SUM(sd.total_available_quantity) AS total_available_quantity
FROM 
    SupplierDetails sd
JOIN 
    PartInfo pi ON sd.part_count > 0
JOIN 
    CustomerOrders c ON sd.s_nationkey = c.c_nationkey
WHERE 
    sd.part_count > 0
GROUP BY 
    sd.s_name
ORDER BY 
    total_revenue DESC, distinct_parts DESC;
