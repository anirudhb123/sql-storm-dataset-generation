WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    COALESCE(ts.total_revenue, 0) AS revenue,
    COALESCE(ts.total_orders, 0) AS orders_count
FROM 
    region r
LEFT JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    TopSuppliers ts ON ns.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = ts.s_suppkey AND ts.revenue_rank = 1)
WHERE 
    r.r_name IN ('Africa', 'Asia') 
ORDER BY 
    r.r_name, revenue DESC;
