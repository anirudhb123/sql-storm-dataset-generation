
WITH BestSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
QualifiedOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_order_value,
        h.rank AS customer_rank
    FROM 
        OrderDetails od
    JOIN 
        HighValueCustomers h ON EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = h.c_custkey AND o.o_orderkey = od.o_orderkey)
)
SELECT 
    b.s_name AS supplier_name,
    COUNT(DISTINCT q.o_orderkey) AS total_orders,
    AVG(q.total_order_value) AS average_order_value,
    MAX(q.customer_rank) AS highest_customer_rank
FROM 
    BestSuppliers b
LEFT JOIN 
    QualifiedOrders q ON EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_suppkey = b.s_suppkey AND ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = q.o_orderkey))
GROUP BY 
    b.s_suppkey, b.s_name
ORDER BY 
    total_orders DESC, average_order_value DESC;
