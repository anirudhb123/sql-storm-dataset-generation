WITH supplier_part_summary AS (
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
order_summary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
detailed_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        sp.total_available_qty,
        sp.total_supply_cost,
        os.total_order_value
    FROM 
        part p
    JOIN 
        supplier_part_summary sp ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey LIMIT 1)
    JOIN 
        order_summary os ON os.total_order_value > 1000
)
SELECT 
    d.p_partkey,
    d.p_name,
    d.total_available_qty,
    d.total_supply_cost,
    d.total_order_value
FROM 
    detailed_summary d
WHERE 
    d.total_available_qty > 100
ORDER BY 
    d.total_order_value DESC
LIMIT 50;