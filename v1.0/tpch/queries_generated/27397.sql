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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(ps.ps_partkey) AS supply_count 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_size,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    CustomerOrders co ON co.total_spent > 100000
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_spent DESC;
