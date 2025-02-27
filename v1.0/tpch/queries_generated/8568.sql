WITH SupplierStats AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
),
CustomerStats AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
PartStats AS (
    SELECT 
        p.p_name AS part_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
)
SELECT 
    ss.supplier_name,
    ss.nation_name,
    cs.customer_name,
    cs.total_order_value,
    ps.part_name,
    ps.avg_supply_cost,
    ps.max_avail_qty
FROM 
    SupplierStats ss
JOIN 
    CustomerStats cs ON cs.total_order_value > 10000
JOIN 
    PartStats ps ON ps.avg_supply_cost < 50.00
ORDER BY 
    ss.total_supply_value DESC, cs.order_count DESC;
