WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_nationkey
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(DISTINCT lo.l_partkey) AS unique_parts,
        MIN(lo.l_shipdate) AS first_shipdate,
        MAX(lo.l_shipdate) AS last_shipdate
    FROM 
        lineitem lo
    JOIN 
        TopOrders to ON lo.l_orderkey = to.o_orderkey
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    n.n_name AS nation,
    od.o_orderkey,
    od.total_revenue,
    od.unique_parts,
    od.first_shipdate,
    od.last_shipdate
FROM 
    OrderDetails od
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderkey = od.o_orderkey)
ORDER BY 
    total_revenue DESC, od.o_orderkey;
