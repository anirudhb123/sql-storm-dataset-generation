WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY ro.o_orderkey ORDER BY ro.o_totalprice DESC) AS row_num
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    WHERE 
        ro.order_rank <= 5
),
OrderDetails AS (
    SELECT 
        to.o_orderkey,
        to.o_orderdate,
        to.o_totalprice,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        TopOrders to
    JOIN 
        lineitem l ON to.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        to.o_orderkey, to.o_orderdate, to.o_totalprice, n.n_name
)
SELECT 
    od.o_orderkey, 
    od.o_orderdate, 
    od.o_totalprice, 
    od.nation_name, 
    od.revenue
FROM 
    OrderDetails od
WHERE 
    od.revenue > 10000
ORDER BY 
    od.o_orderdate DESC, 
    od.revenue DESC;
