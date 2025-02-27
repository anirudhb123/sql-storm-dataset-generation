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
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_amount
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    CustomerOrders co ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE 
    rp.rank = 1 AND ts.rank <= 10
ORDER BY 
    rp.p_retailprice DESC, co.total_amount DESC;
