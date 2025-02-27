WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available_qty,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_spent,
    co.order_count
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    CustomerOrders co ON co.total_spent > 500 
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, ts.parts_supplied DESC, co.total_spent DESC;
