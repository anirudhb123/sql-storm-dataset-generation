
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
), FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal >= 0 AND c.c_acctbal < 10000 THEN 'Low'
            WHEN c.c_acctbal >= 10000 AND c.c_acctbal < 50000 THEN 'Medium'
            ELSE 'High' 
        END AS account_range
    FROM 
        customer c
    WHERE 
        c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1998-10-01' - INTERVAL '30 DAY' AND DATE '1998-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    c.c_name,
    c.c_acctbal,
    r.s_name AS top_supplier,
    os.total_revenue,
    COUNT(os.o_orderkey) AS total_orders
FROM 
    FilteredCustomers c 
LEFT JOIN 
    RankedSuppliers r ON r.rn = 1
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = c.c_custkey
    )
WHERE 
    c.account_range IN ('Medium', 'High')
  AND r.s_suppkey IS NOT NULL
GROUP BY 
    c.c_name, c.c_acctbal, r.s_name, os.total_revenue
ORDER BY 
    c.c_acctbal DESC
LIMIT 10;
