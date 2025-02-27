WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
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
        ro.rank <= 10
),
OrderDetails AS (
    SELECT 
        to.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(li.l_orderkey) AS item_count
    FROM 
        TopOrders to
    JOIN 
        lineitem li ON to.o_orderkey = li.l_orderkey
    GROUP BY 
        to.o_orderkey
)
SELECT 
    tod.o_orderkey,
    tod.total_revenue,
    tod.item_count,
    to.o_orderdate,
    to.c_name,
    to.nation_name
FROM 
    OrderDetails tod
JOIN 
    TopOrders to ON tod.o_orderkey = to.o_orderkey
ORDER BY 
    tod.total_revenue DESC, 
    to.o_orderdate ASC;
