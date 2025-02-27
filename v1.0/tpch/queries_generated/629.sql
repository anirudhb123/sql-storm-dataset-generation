WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)

SELECT 
    c.c_name,
    coalesce(r.s_name, 'No Supplier') AS supplier_name,
    r.s_acctbal,
    coalesce(co.total_spent, 0) AS customer_spent,
    coalesce(co.total_orders, 0) AS order_count,
    COUNT(h.o_orderkey) AS high_value_order_count
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers r ON r.rnk = 1
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN 
    nation n ON r.s_suppkey = n.n_nationkey
WHERE 
    coalesce(co.total_spent, 0) > 20000
GROUP BY 
    c.c_name, r.s_name, r.s_acctbal, co.total_spent, co.total_orders
ORDER BY 
    co.total_spent DESC;
