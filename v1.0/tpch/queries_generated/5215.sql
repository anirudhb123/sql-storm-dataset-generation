WITH SupplierStats AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, n.n_name
),
OrderStats AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    ss.supplier_name,
    ss.nation_name,
    os.customer_name,
    os.o_orderdate,
    os.total_order_value,
    ss.total_available_quantity,
    ss.total_supply_cost
FROM 
    SupplierStats ss
JOIN 
    OrderStats os ON ss.total_supply_cost > 10000
ORDER BY 
    ss.nation_name, os.total_order_value DESC
LIMIT 50;
