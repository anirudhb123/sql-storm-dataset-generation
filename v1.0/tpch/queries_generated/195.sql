WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
HighValueCustomers AS (
    SELECT 
        cust.c_custkey, 
        cust.c_name
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(high_value.c_name, 'Not a High-Value Customer') AS high_value_cust_name,
    COUNT(DISTINCT l.l_orderkey) AS orders_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(l.l_quantity) AS total_units,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_units
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.supplier_rank = 1
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers high_value ON o.o_custkey = high_value.c_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, p.p_retailprice, s.s_name, high_value.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;
