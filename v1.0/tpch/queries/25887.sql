WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_brand LIKE 'Brand%T'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone
    HAVING 
        SUM(ps.ps_availqty) > 100
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name, 
    rp.p_mfgr, 
    rp.p_brand, 
    rp.p_size, 
    sd.s_name AS supplier_name, 
    sd.total_supply_cost, 
    coc.c_name AS customer_name, 
    coc.order_count
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN 
    CustomerOrderCount coc ON coc.order_count > 5
WHERE 
    rp.rn <= 3
ORDER BY 
    rp.p_retailprice DESC, sd.total_supply_cost ASC;
