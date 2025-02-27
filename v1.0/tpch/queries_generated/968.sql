WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    ns.n_name,
    ns.total_suppliers,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    SUM(CASE WHEN la.revenue_rank <= 5 THEN la.net_revenue ELSE 0 END) AS top_revenue_from_top_items,
    AVG(ss.avg_supply_cost) AS avg_supply_cost_across_suppliers,
    COUNT(DISTINCT la.l_orderkey) AS total_line_items
FROM 
    (SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
     FROM 
        nation n
     LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
     GROUP BY 
        n.n_name) ns
LEFT JOIN 
    CustomerOrderStats cs ON cs.total_orders > 0
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = la.l_orderkey))
GROUP BY 
    ns.n_name, cs.c_name
HAVING 
    SUM(CASE WHEN la.net_revenue IS NULL THEN 0 ELSE la.net_revenue END) > 10000
ORDER BY 
    ns.total_suppliers DESC, cs.total_spent DESC;
