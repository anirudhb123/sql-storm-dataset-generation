WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity_per_item
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT cs.c_custkey) AS number_of_customers,
    SUM(cs.total_spent) AS total_revenue_from_customers,
    COUNT(DISTINCT rs.s_suppkey) AS number_of_suppliers,
    SUM(rs.total_supply_value) AS total_supply_value,
    AVG(ls.avg_quantity_per_item) AS average_quantity_per_order
FROM 
    RankedSuppliers rs
JOIN 
    CustomerOrderStats cs ON rs.s_nationkey = cs.c_custkey
JOIN 
    LineItemStats ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    nation ASC;
