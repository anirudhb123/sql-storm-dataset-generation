WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        LENGTH(p.p_comment) AS comment_length
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
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
EnhancedSupplierOrderDetails AS (
    SELECT 
        spd.s_name,
        co.c_name,
        co.o_orderdate,
        co.total_order_value,
        COALESCE(spd.short_comment, 'No Comment') AS supplier_comment,
        COALESCE(spd.comment_length, 0) AS comment_length
    FROM 
        SupplierPartDetails spd
    RIGHT JOIN 
        CustomerOrders co ON spd.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps 
                                               WHERE ps.ps_partkey = (SELECT TOP 1 p.p_partkey 
                                                                      FROM part p 
                                                                      WHERE p.p_brand = 'Brand#45' 
                                                                      ORDER BY p.p_retailprice DESC LIMIT 1)
                                               LIMIT 1)
)
SELECT 
    s.s_name AS SupplierName,
    c.c_name AS CustomerName,
    o.o_orderdate AS OrderDate,
    o.total_order_value AS OrderValue,
    o.supplier_comment AS SupplierComment,
    o.comment_length AS CommentLength
FROM 
    EnhancedSupplierOrderDetails o
WHERE 
    o.total_order_value > 1000
ORDER BY 
    o.total_order_value DESC;
