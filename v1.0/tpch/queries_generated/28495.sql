WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS unique_statuses
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_available_quantity
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS total_orders,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    c.total_orders,
    c.total_spent,
    c.last_order_date,
    c.unique_statuses,
    s.s_name AS supplier_name,
    s.total_parts_supplied,
    s.total_supply_cost,
    s.avg_available_quantity,
    p.p_name AS part_name,
    p.total_orders AS part_total_orders,
    p.total_quantity_sold
FROM 
    CustomerOrderStats c
JOIN 
    SupplierPartStats s ON c.c_custkey % 10 = s.s_suppkey % 10  -- arbitrary join condition for correlation
JOIN 
    PartPopularity p ON c.total_orders IS NOT NULL AND p.total_orders > 0
ORDER BY 
    c.total_spent DESC, s.total_supply_cost DESC, p.total_quantity_sold DESC
LIMIT 100;
