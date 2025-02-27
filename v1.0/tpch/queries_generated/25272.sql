WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%fragile%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        REPLACE(s.s_comment, 'requires', 'needs') AS modified_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    rp.p_name, 
    rp.p_retailprice, 
    co.c_name, 
    co.order_count, 
    co.total_spent, 
    sd.s_name AS supplier_name, 
    sd.modified_comment
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON rp.p_size <= co.order_count
JOIN 
    SupplierDetails sd ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_spent DESC;
