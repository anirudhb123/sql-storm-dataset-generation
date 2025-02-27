WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        SUM(li.l_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
), FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.supplier_name,
        ro.total_quantity,
        ro.order_rank
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    fo.*,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    FilteredOrders fo
JOIN 
    customer c ON fo.c_name = c.c_name
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    fo.o_totalprice DESC;
