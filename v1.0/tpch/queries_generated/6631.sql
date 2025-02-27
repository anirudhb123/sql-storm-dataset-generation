WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_nationkey
    FROM
        ranked_orders ro
    WHERE 
        ro.order_rank <= 10
),
order_details AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(DISTINCT lo.l_partkey) AS part_count
    FROM 
        lineitem lo
    JOIN 
        top_orders to ON lo.l_orderkey = to.o_orderkey
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.c_name,
    to.c_nationkey,
    od.revenue,
    od.part_count,
    n.n_name AS nation_name
FROM 
    top_orders to
JOIN 
    order_details od ON to.o_orderkey = od.l_orderkey
JOIN 
    nation n ON to.c_nationkey = n.n_nationkey
ORDER BY 
    od.revenue DESC, to.o_orderkey;
