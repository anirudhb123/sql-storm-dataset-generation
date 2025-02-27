WITH SupplierSales AS (
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
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate >= DATE '2022-01-01' AND 
        l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RevenueRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_revenue,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY s.total_orders DESC) AS order_rank
    FROM 
        SupplierSales s
), 
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_revenue,
        r.total_orders,
        CASE 
            WHEN r.revenue_rank <= 10 THEN 'Top 10 Revenue' 
            ELSE 'Other' 
        END AS revenue_category,
        CASE 
            WHEN r.order_rank <= 10 THEN 'Top 10 Orders' 
            ELSE 'Other' 
        END AS order_category
    FROM 
        RevenueRanking r
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    t.total_orders,
    t.revenue_category,
    t.order_category,
    COALESCE(r.r_name, 'Unknown') AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    TopSuppliers t
LEFT JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
GROUP BY 
    t.s_suppkey, t.s_name, t.total_revenue, t.total_orders, t.revenue_category, t.order_category, r.r_name
ORDER BY 
    t.total_revenue DESC, t.total_orders DESC;
