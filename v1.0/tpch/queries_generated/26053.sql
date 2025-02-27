WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    sp.supplier_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    co.customer_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice
FROM 
    RankedParts rp
JOIN 
    SupplierParts sp ON rp.p_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = rp.p_partkey
    )
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    sp.ps_supplycost ASC;
