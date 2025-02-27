
WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 1000 THEN 'High'
            WHEN c.c_acctbal > 500 THEN 'Medium'
            ELSE 'Low' 
        END AS customer_value,
        c.c_nationkey
    FROM 
        customer c
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '60 days'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(r.s_acctbal, 0)) AS total_supplier_acctbal,
    AVG(ro.total_order_value) AS avg_recent_order_value,
    COUNT(DISTINCT ro.o_orderkey) AS recent_order_count
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers r ON s.s_suppkey = r.s_suppkey AND r.rank = 1
LEFT JOIN 
    HighValueCustomers c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    RecentOrders ro ON c.c_custkey = ro.o_custkey
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_supplier_acctbal DESC;
