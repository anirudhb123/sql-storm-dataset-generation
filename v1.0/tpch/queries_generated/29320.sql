WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 15
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' - ', s.s_phone) AS supplier_detail,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.name_length,
    rp.p_size,
    rp.p_retailprice,
    si.supplier_detail,
    ci.c_name,
    ci.total_orders,
    rp.price_rank
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON rp.p_partkey = si.total_parts
JOIN 
    CustomerInfo ci ON si.total_parts = ci.total_orders
WHERE 
    rp.price_rank <= 3
ORDER BY 
    rp.name_length DESC, rp.p_retailprice DESC;
