WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_suppkey, s_name
    FROM SupplierRevenue
    WHERE revenue_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name,
    ns.region_name,
    COUNT(DISTINCT TO.s_suppkey) AS total_suppliers,
    COALESCE(SUM(co.total_orders), 0) AS total_customer_orders,
    AVG(sr.total_revenue) AS avg_supplier_revenue
FROM 
    Nations ns
LEFT JOIN 
    TopSuppliers TO ON ns.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = TO.s_suppkey)
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN 
    SupplierRevenue sr ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
        (SELECT l.l_partkey FROM lineitem l)
    )
GROUP BY 
    ns.n_name, ns.region_name
HAVING 
    total_suppliers > 0 OR total_customer_orders > 0
ORDER BY 
    avg_supplier_revenue DESC;
