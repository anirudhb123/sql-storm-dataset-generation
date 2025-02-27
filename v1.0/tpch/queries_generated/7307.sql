WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        sd.s_name,
        sd.nation_name,
        r.order_rank
    FROM 
        RankedOrders r
    JOIN 
        SupplierDetails sd ON r.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = sd.s_suppkey)
    WHERE 
        r.order_rank <= 5
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.s_name,
    h.nation_name
FROM 
    HighValueOrders h
ORDER BY 
    h.o_totalprice DESC, h.o_orderdate ASC;
