WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey
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
)
SELECT 
    n.n_name, 
    COUNT(DISTINCT c.c_custkey) AS total_high_value_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_parts,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE NULL 
    END) AS avg_returned_revenue
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    HighValueCustomers c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
WHERE 
    n.n_name LIKE 'A%' 
    AND (l.l_shipdate > '2022-01-01' OR l.l_returnflag IS NOT NULL)
GROUP BY 
    n.n_name
ORDER BY 
    total_high_value_customers DESC, 
    total_revenue DESC;
