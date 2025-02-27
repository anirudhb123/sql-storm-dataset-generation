WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_comment
    FROM
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
),
StringBenchmark AS (
    SELECT
        sp.s_name,
        CONCAT(sp.p_name, ' (', sp.p_brand, ') - Available: ', CAST(sp.ps_availqty AS VARCHAR), ' units') AS part_info,
        COALESCE(SUBSTRING(co.o_comment, 1, 50), 'No Comments') AS order_comment,
        LENGTH(CONCAT(sp.s_name, sp.p_name, sp.p_brand, co.o_comment)) AS total_string_length
    FROM
        SupplierParts sp
    LEFT JOIN 
        CustomerOrders co ON sp.s_nationkey = co.c_nationkey
)
SELECT 
    s_name,
    part_info,
    order_comment,
    total_string_length
FROM 
    StringBenchmark
WHERE 
    total_string_length > 100
ORDER BY 
    total_string_length DESC;
