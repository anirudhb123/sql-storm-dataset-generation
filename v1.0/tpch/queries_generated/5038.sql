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
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
),
TopOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        r.r_name AS region_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
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
    COUNT(li.l_orderkey) AS line_item_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
FROM 
    TopOrders to
LEFT JOIN 
    lineitem li ON to.o_orderkey = li.l_orderkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice, to.c_name
ORDER BY 
    total_sales DESC
LIMIT 20;
