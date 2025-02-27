WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUBSTRING(p.p_name, 1, 10) AS short_name, 
        LENGTH(p.p_name) AS name_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.short_name, 
    rp.rank_by_price, 
    co.total_orders, 
    sp.total_parts, 
    CONCAT('Supplier: ', sp.s_name, ' - Parts Count: ', sp.total_parts, ' | Orders: ', co.total_orders) AS summary
FROM 
    RankedParts rp
LEFT JOIN 
    CustomerOrders co ON co.total_orders > 10
LEFT JOIN 
    SupplierPartDetails sp ON sp.total_parts > 5
WHERE 
    rp.name_length > 20
ORDER BY 
    rp.rank_by_price DESC, 
    co.total_orders DESC;
