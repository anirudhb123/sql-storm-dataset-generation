WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        CHARINDEX('ANALYSIS', p.p_comment) > 0 OR 
        CHARINDEX('OPTIMIZATION', p.p_comment) > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        p.p_type,
        p.p_retailprice,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    cp.c_name,
    SUM(co.total_spent) AS total_spent_per_customer,
    sp.s_name AS supplier_name,
    sp.ps_availqty,
    sp.s_comment
FROM 
    RankedParts rp
LEFT JOIN 
    CustomerOrders co ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
JOIN 
    SupplierPartDetails sp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
WHERE 
    rp.rn <= 5
GROUP BY 
    rp.p_name, rp.p_brand, rp.p_type, cp.c_name, sp.s_name, sp.ps_availqty, sp.s_comment
ORDER BY 
    total_spent_per_customer DESC, rp.p_retailprice ASC;
