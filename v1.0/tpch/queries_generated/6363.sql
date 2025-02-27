WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopRevenueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    SUM(tr.customer_revenue) AS total_revenue_by_region
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    TopRevenueCustomers tr ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = tr.c_custkey)
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_by_region DESC;
