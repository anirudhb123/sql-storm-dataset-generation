
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),

HighSpendingSuppliers AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)

SELECT 
    r.r_name AS region_name,
    SUM(co.total_spent) AS total_customer_spent,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    COUNT(DISTINCT hs.ps_suppkey) AS high_spending_suppliers
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.rank = 1 AND n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
JOIN 
    CustomerOrders co ON n.n_nationkey = co.c_nationkey
LEFT JOIN 
    HighSpendingSuppliers hs ON hs.ps_suppkey = rs.s_suppkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_customer_spent DESC;
