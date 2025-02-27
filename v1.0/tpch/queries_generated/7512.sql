WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        customer_count DESC
    LIMIT 5
)
SELECT 
    r.r_name AS region_name,
    ss.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_available_quantity,
    ss.total_supply_value
FROM 
    SupplierStats ss
JOIN 
    CustomerStats cs ON cs.total_orders > 0
JOIN 
    TopRegions tr ON cs.c_custkey IS NOT NULL
JOIN 
    nation n ON cs.total_orders > 0
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    cs.total_spent DESC, ss.total_supply_value ASC
LIMIT 100;
