WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT p.p_type, ', ') AS supplied_part_types,
        STRING_AGG(DISTINCT s_n.n_name, ', ') AS associated_nations
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation s_n ON s.s_nationkey = s_n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_items_ordered,
        STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS customer_segments
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    ss.s_name,
    ss.total_parts_supplied,
    ss.total_available_qty,
    ss.total_supply_value,
    ss.avg_supply_cost,
    ss.supplied_part_types,
    os.total_items_ordered,
    os.o_orderdate,
    os.o_totalprice,
    os.customer_segments
FROM 
    SupplierStats ss
JOIN 
    OrderStats os ON ss.total_available_qty = os.total_items_ordered
WHERE 
    ss.total_parts_supplied > 5
ORDER BY 
    ss.total_supply_value DESC, os.o_orderdate DESC;
