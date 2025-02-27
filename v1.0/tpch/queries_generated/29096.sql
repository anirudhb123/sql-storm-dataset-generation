WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container LIKE 'SM%')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        STRING_AGG(DISTINCT p.p_brand, ', ') AS supplied_brands
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_size,
    si.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON rp.p_brand = ANY(STRING_TO_ARRAY(si.supplied_brands, ', '))
JOIN 
    CustomerOrders co ON co.total_spent > rp.p_retailprice
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_spent DESC;
