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
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.total_revenue,
        ROW_NUMBER() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent
FROM 
    NationSupplier ns
LEFT JOIN 
    TopSuppliers ts ON ns.n_nationkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = ns.n_nationkey)
LEFT JOIN 
    CustomerOrders co ON ns.supplier_count > 0
WHERE 
    ts.revenue_rank <= 5 OR ts.supplier_count IS NULL
ORDER BY 
    ns.n_name;
