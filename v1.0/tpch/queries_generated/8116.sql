WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
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
        n.n_name AS nation_name,
        n.n_regionkey
    FROM 
        ranked_orders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
), 
order_summary AS (
    SELECT 
        to.nation_name,
        to.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT to.o_orderkey) AS order_count
    FROM 
        top_orders to
    JOIN 
        lineitem li ON to.o_orderkey = li.l_orderkey
    GROUP BY 
        to.nation_name, to.o_orderdate
)
SELECT 
    os.nation_name, 
    os.o_orderdate, 
    os.total_sales, 
    os.order_count,
    SUM(os.total_sales) OVER (PARTITION BY os.nation_name ORDER BY os.o_orderdate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM 
    order_summary os
ORDER BY 
    os.nation_name, os.o_orderdate DESC;
