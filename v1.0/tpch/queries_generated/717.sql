WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_revenue,
        so.total_orders
    FROM 
        supplier s
    JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
    WHERE 
        so.rn = 1
),
SupplierRegions AS (
    SELECT 
        n.n_nationkey, 
        n.n_name AS nation_name,
        r.r_regionkey,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.region_name,
    ts.s_name,
    ts.total_revenue,
    ts.total_orders,
    CASE 
        WHEN ts.total_revenue IS NULL THEN 'No Revenue' 
        ELSE CONCAT('Revenue: $', FORMAT(ts.total_revenue, 2))
    END AS revenue_statement
FROM 
    SupplierRegions sr
LEFT JOIN 
    TopSuppliers ts ON sr.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = ts.s_suppkey)
ORDER BY 
    sr.region_name, ts.total_revenue DESC;
