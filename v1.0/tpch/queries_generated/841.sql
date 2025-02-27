WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    ts.s_name AS top_supplier,
    ts.total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = s.s_nationkey
    )
WHERE 
    ts.revenue_rank <= 10
GROUP BY 
    n.n_name, r.r_name, ts.s_name, ts.total_revenue
ORDER BY 
    ts.total_revenue DESC;
