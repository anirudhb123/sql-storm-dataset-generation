WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
    ORDER BY 
        region_revenue DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    r.region_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(ro.total_revenue) AS avg_order_revenue
FROM 
    TopRegions tr
JOIN 
    region r ON tr.n_nationkey = r.r_regionkey
JOIN 
    RankedOrders ro ON ro.total_revenue > tr.region_revenue
GROUP BY 
    r.r_name, r.region_revenue
ORDER BY 
    avg_order_revenue DESC;
