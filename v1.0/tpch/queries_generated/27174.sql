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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
        AND LENGTH(p.p_comment) > 10
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 2
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    CustomerOrders co ON co.order_count = (SELECT MAX(order_count) FROM CustomerOrders)
WHERE 
    rp.brand_rank <= 3
ORDER BY 
    rp.p_retailprice DESC, co.order_count DESC;
