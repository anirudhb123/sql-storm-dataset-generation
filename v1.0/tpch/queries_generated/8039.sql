WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        AVG(l.l_extendedprice) AS avg_price_per_unit
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ss.s_name,
    cs.c_name,
    ps.p_name,
    ss.part_count,
    cs.order_count,
    ps.total_quantity_sold,
    ps.avg_price_per_unit,
    ss.total_supply_cost,
    cs.total_spent
FROM 
    SupplierStats ss
JOIN 
    CustomerStats cs ON ss.part_count > cs.order_count
JOIN 
    PartStats ps ON ss.part_count <= ps.total_quantity_sold
WHERE 
    ss.total_supply_cost > 1000.00
ORDER BY 
    cs.total_spent DESC, ss.total_supply_cost ASC
LIMIT 100;
