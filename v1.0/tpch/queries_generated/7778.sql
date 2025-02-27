WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON ps.ps_partkey = l.l_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_name) AS unique_customers
FROM 
    RankedOrders o
JOIN 
    nation n ON n.n_nationkey = o.c_custkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    o.order_rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
