WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 

FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 1000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END as customer_segment
    FROM 
        customer c
    WHERE 
        c.c_comment IS NOT NULL
)

SELECT 
    n.n_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(RANKED.rank) as max_supplier_rank,
    STRING_AGG(DISTINCT f.customer_segment || ' (' || f.c_custkey || ')', ', ') AS customer_segments_count
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    RankedSuppliers RANKED ON s.s_suppkey = RANKED.s_suppkey
JOIN 
    FilteredCustomers f ON o.o_custkey = f.c_custkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND cast('1998-10-01' as date)
    AND l.l_returnflag = 'N'
    AND (l.l_discount < 0.05 OR l.l_tax > 0.1)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC, n.n_name;