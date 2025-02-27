WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.nation
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name AS customer_name,
    to.nation AS customer_nation,
    sp.p_name AS part_name,
    sp.s_name AS supplier_name,
    sp.ps_supplycost
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
ORDER BY 
    to.o_totalprice DESC, 
    to.o_orderdate ASC
LIMIT 50;
