WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
),
TopOrders AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY net_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 5
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(to.net_revenue) AS total_net_revenue,
    COUNT(DISTINCT to.o_orderkey) AS order_count
FROM 
    TopOrders to
JOIN 
    supplier s ON to.o_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(to.net_revenue) > (SELECT AVG(net_revenue) FROM TopOrders)
ORDER BY 
    total_net_revenue DESC;
