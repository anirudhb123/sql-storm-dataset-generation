WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.total_revenue) AS total_revenue_generated
FROM 
    RankedOrders o
JOIN 
    customer c ON o.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_custkey = c.c_custkey
    )
JOIN 
    supplier s ON s.s_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey IN (
            SELECT l_partkey 
            FROM lineitem 
            WHERE l_orderkey = o.o_orderkey
        )
    )
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.order_rank <= 10
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue_generated DESC;
