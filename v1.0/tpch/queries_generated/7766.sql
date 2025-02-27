WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.s_name AS supplier_name,
    h.c_name AS customer_name,
    o.total_lineitem_value AS total_order_value,
    r.total_supply_cost AS supplier_total_cost
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers h ON r.rank <= 10
JOIN 
    OrderDetails o ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = h.c_custkey))
ORDER BY 
    supplier_total_cost DESC, total_order_value DESC;
