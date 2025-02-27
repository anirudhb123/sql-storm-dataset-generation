WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomers AS (
    SELECT 
        revenue_rank, 
        o_orderkey, 
        o_orderdate, 
        c_name,
        revenue
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
)
SELECT 
    rc.r_name AS region_name,
    COUNT(DISTINCT tc.o_orderkey) AS total_orders,
    SUM(tc.revenue) AS total_revenue
FROM 
    TopCustomers tc
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderkey = tc.o_orderkey))
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rc ON n.n_regionkey = rc.r_regionkey
GROUP BY 
    rc.r_name
ORDER BY 
    total_revenue DESC;