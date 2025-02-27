WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    COALESCE(cs.c_name, 'No Customer') AS customer_name,
    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(ls.total_price_after_discount, 0) AS total_revenue,
    ss.total_parts_supplied,
    ss.total_available_quantity,
    ss.average_supply_cost
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    supplier ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    customer cu ON ss.s_suppkey = cu.c_custkey
LEFT JOIN 
    CustomerOrders os ON cu.c_custkey = os.c_custkey
LEFT JOIN 
    LineitemDetails ls ON os.total_orders = ls.l_orderkey
WHERE 
    ss.total_parts_supplied > 5
    AND (ss.average_supply_cost IS NOT NULL OR os.total_spent > 1000)
ORDER BY 
    region_name, nation_name, customer_name;
