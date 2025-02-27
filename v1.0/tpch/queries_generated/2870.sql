WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionPerformance AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(sp.total_supply_cost) AS total_supply_cost_region,
        AVG(cp.total_spent) AS avg_customer_spending
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
    LEFT JOIN 
        CustomerSpending cp ON n.n_nationkey = cp.c_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0 AND AVG(cp.total_spent) IS NOT NULL
)
SELECT 
    r.r_name,
    rp.supplier_count,
    rp.total_supply_cost_region,
    rp.avg_customer_spending,
    COALESCE(sp.total_orders, 0) AS total_orders_supplier,
    COALESCE(sp.total_available_quantity, 0) AS total_available_quantity,
    COALESCE(sp.avg_order_value, 0) AS avg_order_value_supplier
FROM 
    RegionPerformance rp
LEFT JOIN 
    SupplierPerformance sp ON rp.supplier_count = (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey = rp.n_regionkey)
ORDER BY 
    rp.total_supply_cost_region DESC, rp.avg_customer_spending DESC;
