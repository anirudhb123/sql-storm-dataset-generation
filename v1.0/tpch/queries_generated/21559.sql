WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
TopNationSuppliers AS (
    SELECT 
        n.n_name, 
        n.n_nationkey,
        COUNT(*) AS supplier_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
    GROUP BY 
        n.n_name, n.n_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        AVG(o.o_totalprice) IS NOT NULL AND 
        AVG(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), 
SupplierStatistics AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        RankedSuppliers rs
    JOIN 
        lineitem l ON rs.s_suppkey = l.l_suppkey
    GROUP BY 
        rs.s_suppkey, rs.s_name
    HAVING 
        SUM(l.l_quantity) > 100 AND
        SUM(l.l_extendedprice * (1 - l.l_discount)) < 10000
)
SELECT
    n.n_name,
    ns.supplier_count,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    SUM(ss.total_quantity) AS total_ordered_quantity,
    AVG(ss.revenue) AS avg_revenue_per_supplier,
    COALESCE(MAX(CASE WHEN ss.total_quantity > 100 THEN ss.revenue END), 0) AS max_revenue_over_threshold
FROM 
    TopNationSuppliers ns
LEFT JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_custkey
LEFT JOIN 
    SupplierStatistics ss ON ns.n_nationkey = ss.s_suppkey
GROUP BY 
    n.n_name, ns.supplier_count
HAVING 
    COUNT(DISTINCT co.c_custkey) > 5 
ORDER BY 
    total_ordered_quantity DESC, 
    avg_revenue_per_supplier DESC;
