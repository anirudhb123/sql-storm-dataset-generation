WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        p.p_name,
        s.s_name
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
    to.nation_name,
    ps.p_name AS part_name,
    ps.ps_supplycost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    PartSupplier ps ON ps.ps_partkey = l.l_partkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice, to.c_name, to.nation_name, ps.p_name, ps.ps_supplycost
ORDER BY 
    to.o_orderdate DESC, total_lineitem_value DESC;
