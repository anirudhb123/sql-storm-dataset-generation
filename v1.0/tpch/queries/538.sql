WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
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
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    ls.total_revenue,
    sd.s_name,
    sd.nation_name,
    sd.s_acctbal
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
LEFT JOIN 
    SupplierDetails sd ON sd.s_suppkey = (
        SELECT ps2.ps_suppkey 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = ps.ps_partkey
        ORDER BY ps2.ps_supplycost ASC
        LIMIT 1
    )
WHERE 
    r.rn <= 10
    AND (ls.total_revenue IS NOT NULL OR sd.nation_name IS NULL)
ORDER BY 
    r.o_orderkey DESC
LIMIT 50;