WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
), TopRevenue AS (
    SELECT 
        r.r_name,
        SUM(ro.total_revenue) AS region_revenue
    FROM 
        RankedOrders ro
    JOIN 
        supplier s ON EXISTS (
            SELECT 1
            FROM partsupp ps
            WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 30)
            AND ps.ps_suppkey = s.s_suppkey
        )
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank_order <= 10
    GROUP BY 
        r.r_name
)

SELECT 
    r.r_name,
    COALESCE(tr.region_revenue, 0) AS revenue
FROM 
    region r
LEFT JOIN 
    TopRevenue tr ON r.r_name = tr.r_name
ORDER BY 
    revenue DESC;