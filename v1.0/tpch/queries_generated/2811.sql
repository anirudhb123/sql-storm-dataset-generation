WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sos.total_revenue,
        sos.order_count,
        sos.avg_quantity
    FROM 
        supplier s
    JOIN 
        SupplierOrderStats sos ON s.s_suppkey = sos.s_suppkey
    WHERE 
        sos.revenue_rank <= 5
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(t.s_name, 'No Supplier') AS supplier_name,
    COALESCE(t.total_revenue, 0) AS total_revenue,
    COALESCE(t.order_count, 0) AS order_count,
    COALESCE(t.avg_quantity, 0) AS avg_quantity
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers t ON n.n_nationkey = (
        SELECT 
            s_nationkey 
        FROM 
            supplier 
        WHERE 
            s_suppkey = t.s_suppkey
    )
WHERE 
    n.n_name IS NOT NULL
ORDER BY 
    region_name, nation_name;
