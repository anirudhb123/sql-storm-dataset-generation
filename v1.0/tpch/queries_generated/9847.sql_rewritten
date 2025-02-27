WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.price_rank <= 10
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        hlo.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        HighValueOrders hlo
    JOIN 
        lineitem l ON hlo.o_orderkey = l.l_orderkey
    GROUP BY 
        hlo.o_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_mktsegment,
    oi.revenue,
    oi.unique_suppliers,
    p.p_name,
    p.p_brand,
    ps.ps_supplycost
FROM 
    HighValueOrders o
JOIN 
    OrderDetails oi ON o.o_orderkey = oi.o_orderkey
JOIN 
    PartSupplierInfo ps ON ps.ps_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey
    )
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
ORDER BY 
    o.o_orderdate DESC, 
    oi.revenue DESC;