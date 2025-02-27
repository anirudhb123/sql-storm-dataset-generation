WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
        sr.s_suppkey, 
        sr.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    COALESCE(nullif(t.order_count, 0), 'No Orders') AS order_count,
    CONCAT('Supplier: ', t.s_name, ' has generated a revenue of ', FORMAT(t.total_revenue, 2), ' with ', COALESCE(t.order_count::text, '0'), ' orders.') AS revenue_comment
FROM 
    TopSuppliers t
WHERE 
    t.revenue_rank <= 10
    OR (t.s_name LIKE '%Supplier%' AND t.total_revenue > 10000)
ORDER BY 
    t.total_revenue DESC;

SELECT 
    r.r_name, 
    SUM(sr.total_revenue) AS region_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
GROUP BY 
    r.r_name
HAVING 
    SUM(sr.total_revenue) IS NOT NULL;

