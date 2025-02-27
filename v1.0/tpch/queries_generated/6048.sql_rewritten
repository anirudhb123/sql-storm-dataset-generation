WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_mktsegment
),
TopRevenueSegments AS (
    SELECT 
        c.c_mktsegment,
        SUM(total_revenue) AS segment_revenue
    FROM 
        RankedOrders r
    JOIN 
        customer c ON r.c_name = c.c_name
    WHERE 
        r.revenue_rank <= 5
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    t.c_mktsegment,
    t.segment_revenue,
    r.r_name AS region,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    TopRevenueSegments t
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_mktsegment = t.c_mktsegment LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#123')
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    t.c_mktsegment, t.segment_revenue, r.r_name
ORDER BY 
    t.segment_revenue DESC;