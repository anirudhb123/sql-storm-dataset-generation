WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%' 
        AND p.p_retailprice > 100.00
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000.00
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 2000.00
)

SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_type,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    ci.nation_name,
    co.total_revenue,
    co.o_orderdate
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    CustomerOrders co ON si.s_nationkey = co.o_custkey
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_revenue DESC;
