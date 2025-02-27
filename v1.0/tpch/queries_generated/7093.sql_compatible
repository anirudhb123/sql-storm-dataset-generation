
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_discount) AS avg_discount,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ss.s_name,
    ss.total_available_qty,
    ss.total_supply_cost,
    os.total_orders,
    os.total_spent,
    lid.total_revenue,
    lid.avg_discount,
    lid.unique_parts
FROM 
    SupplierStats ss
JOIN 
    OrderStats os ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty = ss.total_available_qty LIMIT 1)
JOIN 
    LineItemDetails lid ON lid.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = os.c_custkey LIMIT 1)
ORDER BY 
    ss.total_supply_cost DESC, os.total_spent DESC;
