WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        MAX(l.l_shipdate) as latest_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ss.s_name,
    ss.total_supply_value,
    ss.part_count,
    os.total_order_value,
    os.latest_ship_date
FROM 
    SupplierStats ss
LEFT JOIN 
    OrderStats os ON ss.part_count > 5 AND ss.total_supply_value > 10000
ORDER BY 
    ss.total_supply_value DESC, 
    os.total_order_value DESC
LIMIT 100;
