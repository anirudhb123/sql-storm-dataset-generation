WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        r.total_revenue,
        o.o_orderdate
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 100
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        s.s_suppkey
),
FinalReport AS (
    SELECT 
        to.o_orderkey,
        to.total_revenue,
        sr.supplier_revenue,
        CASE 
            WHEN sr.supplier_revenue IS NULL THEN 0 
            ELSE sr.supplier_revenue END AS effective_supplier_revenue
    FROM 
        TopOrders to
    LEFT JOIN 
        SupplierRevenue sr ON to.o_orderkey = sr.s_suppkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    SUM(f.effective_supplier_revenue) AS total_effective_revenue,
    SUM(f.total_revenue) AS total_order_revenue
FROM 
    FinalReport f
JOIN 
    orders o ON f.o_orderkey = o.o_orderkey
GROUP BY 
    o.o_orderkey, o.o_orderdate
ORDER BY 
    total_order_revenue DESC
LIMIT 10;
