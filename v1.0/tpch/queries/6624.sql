WITH RegionalStats AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, n.n_name
),
OrderStats AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rs.region_name,
    rs.nation_name,
    rs.total_available_quantity,
    rs.average_supply_cost,
    os.total_order_value,
    os.total_orders
FROM 
    RegionalStats rs
LEFT JOIN 
    OrderStats os ON rs.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = os.c_nationkey)
WHERE 
    rs.total_available_quantity > 1000 
ORDER BY 
    rs.region_name, rs.nation_name;
