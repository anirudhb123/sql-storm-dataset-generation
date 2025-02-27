WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 

RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),

CustomerData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        RecentOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)

SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(CASE WHEN rs.supply_rank = 1 THEN rs.total_supply_cost END) AS top_supplier_cost,
    AVG(cd.order_count) AS avg_orders_per_customer
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.n_nationkey = n.n_nationkey
JOIN 
    CustomerData cd ON rs.s_nationkey = cd.c_nationkey
LEFT JOIN 
    customer cs ON cs.c_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    nation;
