WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_totalprice,
        r.o_orderdate,
        r.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        RankedOrders r 
    LEFT JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.o_orderkey, r.o_totalprice, r.o_orderdate, r.c_name
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.c_name,
    h.total_value,
    s.p_name,
    s.s_name,
    s.s_acctbal
FROM 
    HighValueOrders h
JOIN 
    SupplierInfo s ON s.ps_partkey = (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = h.o_orderkey
        ORDER BY 
            l.l_extendedprice DESC 
        LIMIT 1
    )
WHERE 
    h.total_value > 500 
    AND h.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
ORDER BY 
    h.o_orderdate, h.c_name;