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
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    sd.s_name AS supplier_name, 
    cd.c_name AS customer_name, 
    cd.o_totalprice
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerOrders cd ON cd.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = rp.p_partkey
    )
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, 
    cd.o_totalprice DESC;
