WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS total_order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.nation_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.total_order_rank <= 10
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.c_name,
    to.nation_name,
    od.total_revenue,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = to.o_orderkey) AS line_item_count
FROM 
    TopOrders to
LEFT JOIN 
    OrderDetails od ON to.o_orderkey = od.l_orderkey
ORDER BY 
    to.o_orderdate DESC;
