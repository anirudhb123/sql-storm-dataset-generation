WITH String_Benchmark AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_name) AS name_length,
        CONCAT(p.p_brand, ' ', p.p_type, ' ', p.p_container) AS full_description,
        REPLACE(p.p_comment, 'poor', 'excellent') AS upgraded_comment,
        TRIM(SUBSTR(p.p_name, 1, 30)) AS trimmed_name
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT l.l_quantity FROM lineitem l WHERE l.l_quantity > 10)
),
Supplier_Benchmark AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' ', s.s_address) AS supplier_info,
        LEFT(s.s_comment, 50) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
Customer_Benchmark AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        REPLACE(c.c_address, 'Street', 'St.') AS normalized_address,
        UPPER(c.c_mktsegment) AS upper_segment,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal >= 0
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_mktsegment
)
SELECT 
    sb.p_partkey, 
    sb.upper_name, 
    sb.lower_comment, 
    sb.name_length, 
    sb.full_description, 
    sb.upgraded_comment, 
    sb.trimmed_name, 
    su.s_suppkey, 
    su.supplier_info, 
    su.short_comment, 
    cb.c_custkey, 
    cb.c_name, 
    cb.normalized_address, 
    cb.upper_segment, 
    cb.total_orders
FROM 
    String_Benchmark sb
JOIN 
    Supplier_Benchmark su ON sb.p_partkey % 10 = su.s_suppkey % 10
JOIN 
    Customer_Benchmark cb ON cb.total_orders > 5
ORDER BY 
    sb.name_length DESC, cb.total_orders ASC;
