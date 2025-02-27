WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY pn.p_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part pn ON ps.ps_partkey = pn.p_partkey
), TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), HighSpenders AS (
    SELECT 
        cust.c_custkey,
        cust.order_count,
        cust.total_spent
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    MAX(CASE WHEN l.l_shipdate > CURRENT_DATE THEN 'Pending' ELSE 'Completed' END) AS order_status,
    (SELECT STRING_AGG(DISTINCT ts.s_name, ', ') 
     FROM TopSuppliers ts
     JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
     WHERE ps.ps_partkey = p.p_partkey) AS top_suppliers
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighSpenders hs ON hs.cust.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_sales DESC;
