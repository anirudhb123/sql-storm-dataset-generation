
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(o.total_value) AS max_order_value,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    ROUND(AVG(cs.total_spent), 2) AS avg_customer_spent
FROM 
    partsupp ps 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 5
LEFT JOIN 
    HighValueOrders o ON ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1)
LEFT JOIN 
    CustomerOrderStats cs ON cs.order_count > 0
WHERE 
    p.p_retailprice BETWEEN 50.00 AND 200.00 AND 
    (p.p_comment LIKE '%redundant%' OR p.p_container IS NULL)
GROUP BY 
    ps.ps_partkey, p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, avg_customer_spent DESC
LIMIT 10;
