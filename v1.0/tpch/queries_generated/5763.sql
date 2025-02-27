WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
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
        ro.rn <= 10
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    to.nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(l.l_orderkey) AS item_count
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice, to.c_name, to.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 50;
