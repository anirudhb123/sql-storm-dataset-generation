
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment
    FROM 
        supplier s 
    WHERE 
        LENGTH(s.s_name) > 10
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_by_totalprice
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    rp.p_name AS part_name, 
    s.s_name AS supplier_name, 
    co.o_orderkey AS order_key, 
    co.o_totalprice, 
    co.c_name AS customer_name, 
    co.o_orderdate,
    rp.rank_by_price,
    co.rank_by_totalprice
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    CustomerOrders co ON co.o_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey = (
                SELECT 
                    l.l_orderkey 
                FROM 
                    lineitem l 
                WHERE 
                    l.l_partkey = rp.p_partkey 
                LIMIT 1
            )
    )
WHERE 
    rp.rank_by_price <= 5 
    AND co.rank_by_totalprice <= 10
ORDER BY 
    rp.p_retailprice DESC, co.o_totalprice DESC;
