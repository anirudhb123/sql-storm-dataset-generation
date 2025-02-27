WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-10-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderstatus,
        r.o_totalprice,
        r.o_orderdate,
        r.o_orderpriority,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        p.p_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    o.o_orderpriority,
    o.c_mktsegment,
    s.s_name,
    s.s_acctbal,
    s.ps_supplycost,
    s.p_name
FROM 
    TopOrders o
JOIN 
    SupplierDetails s ON o.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1)
WHERE 
    s.ps_supplycost < 100.00
ORDER BY 
    o.o_totalprice DESC, 
    o.o_orderdate ASC;
