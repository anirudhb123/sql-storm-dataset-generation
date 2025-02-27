WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS total_parts_supplied,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
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
)
SELECT 
    sa.s_name AS supplier_name,
    sa.total_supply_cost,
    sa.total_parts_supplied,
    COALESCE(co.total_orders, 0) AS customer_orders_count,
    COALESCE(co.total_spent, 0.00) AS customer_total_spent,
    sa.part_names,
    sa.regions_supplied
FROM 
    SupplierAggregates sa
LEFT JOIN 
    CustomerOrders co ON sa.s_suppkey = co.c_custkey
ORDER BY 
    sa.total_supply_cost DESC, 
    co.total_spent DESC
LIMIT 10;
