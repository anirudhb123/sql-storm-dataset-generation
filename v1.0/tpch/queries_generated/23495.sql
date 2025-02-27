WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
LargeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        O.o_orderpriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderpriority
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
HighAcctBalSuppliers AS (
    SELECT 
        r.r_name,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal IS NOT NULL
        AND s.rn <= 5
),
NullFilter AS (
    SELECT 
        o.o_orderkey,
        COALESCE(lo.total_amount, 0) AS order_total,
        CASE WHEN lo.o_orderpriority IS NULL THEN 'UNKNOWN' ELSE lo.o_orderpriority END AS order_priority
    FROM 
        LargeOrders lo
    FULL OUTER JOIN 
        orders o ON lo.o_orderkey = o.o_orderkey
)
SELECT 
    hb.s_name AS supplier_name,
    hb.r_name AS region_name,
    nf.order_total,
    nf.order_priority,
    COUNT(f.ps_partkey) AS part_count
FROM 
    HighAcctBalSuppliers hb
LEFT JOIN 
    partsupp f ON hb.s_suppkey = f.ps_suppkey
LEFT JOIN 
    NullFilter nf ON nf.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hb.s_nationkey LIMIT 1)
WHERE 
    hb.s_acctbal BETWEEN 1000 AND 5000
    AND hb.s_name <> 'UNKNOWN SUPPLIER'
GROUP BY 
    hb.s_name, hb.r_name, nf.order_total, nf.order_priority
ORDER BY 
    hb.r_name, nf.order_total DESC, hb.s_name;
