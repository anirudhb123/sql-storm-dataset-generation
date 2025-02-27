WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderpriority
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.order_revenue,
        o.o_orderstatus,
        o.o_orderdate,
        c.c_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    t.o_orderkey,
    t.order_revenue,
    t.o_orderstatus,
    t.o_orderdate,
    t.c_name,
    t.nation_name,
    t.supplier_name
FROM 
    TopOrders t
ORDER BY 
    t.order_revenue DESC;