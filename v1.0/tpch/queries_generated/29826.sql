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
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_size,
    rp.p_container,
    rp.p_retailprice,
    rp.p_comment,
    si.s_name AS supplier_name,
    si.total_parts,
    si.total_supplycost,
    co.c_name AS customer_name,
    co.order_value
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON si.total_parts > 10
JOIN 
    CustomerOrders co ON co.o_orderstatus = 'O'
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, si.total_supplycost ASC
LIMIT 100;
