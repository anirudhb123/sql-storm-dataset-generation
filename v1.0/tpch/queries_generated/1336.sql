WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerAggregate AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    s.s_name,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(h.total_order_value) AS total_high_value_orders,
    AVG(cs.total_spent) AS average_customer_spending,
    MAX(s.total_supply_cost) AS max_supplier_cost,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations
FROM 
    SupplierStats s
JOIN 
    CustomerAggregate cs ON cs.order_count > 0
JOIN 
    HighValueOrders h ON h.o_custkey = cs.c_custkey
JOIN 
    supplier su ON s.s_suppkey = su.s_suppkey
LEFT JOIN 
    nation n ON su.s_nationkey = n.n_nationkey
WHERE 
    s.total_parts > 5
GROUP BY 
    s.s_name
ORDER BY 
    total_high_value_orders DESC,
    average_customer_spending ASC;
