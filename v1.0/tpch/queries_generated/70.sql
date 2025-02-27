WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    p.p_name,
    AVG(total_revenue) AS avg_revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT CASE WHEN ps.ps_availqty < 100 THEN ps.ps_suppkey END) AS low_availability_suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rn = 1
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderDetails od ON p.p_partkey = od.o_orderkey  -- Assuming a relation for demonstration
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, p.p_name
HAVING 
    AVG(total_revenue) > 1000
ORDER BY 
    avg_revenue DESC, customer_count DESC;
