WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
            WHERE s2.s_nationkey = n.n_nationkey
        )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    si.s_name,
    si.nation_name,
    co.order_count,
    co.total_spent,
    hvo.total_value
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
LEFT JOIN 
    CustomerOrders co ON si.s_nationkey = co.c_custkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = co.c_custkey
WHERE 
    (hvo.total_value IS NULL OR hvo.total_value > 500)
    AND (rp.rn <= 5 OR si.s_acctbal > 10000)
ORDER BY 
    rp.p_retailprice DESC, 
    si.s_name;
