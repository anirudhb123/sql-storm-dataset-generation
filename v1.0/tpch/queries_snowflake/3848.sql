
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        COUNT(ps.ps_suppkey) AS suppliers_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(s.s_suppkey) AS total_suppliers
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
)
SELECT 
    h.order_value,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ss.total_acctbal,
    ss.total_suppliers
FROM 
    HighValueOrders h
JOIN 
    RankedParts rp ON rp.price_rank = 1
LEFT JOIN 
    SupplierSummary ss ON ss.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE s.s_suppkey = (
            SELECT MIN(ps.ps_suppkey)
            FROM partsupp ps 
            WHERE ps.ps_partkey = rp.p_partkey
        )
    )
WHERE 
    h.order_value > 1000
ORDER BY 
    h.order_value DESC,
    rp.p_retailprice ASC
LIMIT 50
