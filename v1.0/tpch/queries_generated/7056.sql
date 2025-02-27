WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    rs.s_name AS supplier_name, 
    hvc.c_name AS customer_name, 
    od.order_value, 
    od.o_orderdate
FROM 
    part p
JOIN 
    RankedSuppliers rs ON rs.rnk = 1 AND p.p_partkey = rs.ps_partkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey IN (SELECT DISTINCT o.o_custkey 
                                                   FROM orders o 
                                                   JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                                   WHERE l.l_partkey = p.p_partkey)
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey 
                                            FROM orders o 
                                            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                            WHERE l.l_partkey = p.p_partkey)
WHERE 
    p.p_retailprice > 50.00
ORDER BY 
    od.order_value DESC
LIMIT 10;
