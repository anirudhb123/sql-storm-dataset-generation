WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
top_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY o.o_totalprice DESC) AS top_rank
    FROM 
        ranked_orders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank <= 10
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    to.region_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(li.l_orderkey) AS total_items
FROM 
    top_orders to
JOIN 
    lineitem li ON to.o_orderkey = li.l_orderkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice, to.c_name, to.region_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
