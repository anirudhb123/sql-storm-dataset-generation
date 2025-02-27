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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
), 
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    rp.p_name AS part_name,
    rp.p_brand AS brand,
    rp.p_retailprice AS price,
    sd.s_name AS supplier_name,
    sd.s_acctbal AS supplier_account_balance,
    co.c_name AS customer_name,
    co.o_totalprice AS order_total,
    co.o_orderdate AS order_date
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey = sd.ps_partkey AND sd.supplier_rank = 1
JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_partkey = rp.p_partkey
    )
WHERE 
    rp.rank <= 5 AND co.order_rank <= 10
ORDER BY 
    rp.p_type, rp.p_retailprice DESC, co.o_orderdate DESC;
