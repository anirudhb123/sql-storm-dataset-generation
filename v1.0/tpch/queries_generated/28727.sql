WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 5000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS cust_value_segment
    FROM 
        customer c
)
SELECT 
    n.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.part_count,
    hvc.c_name AS customer_name,
    hvc.c_acctbal,
    hvc.cust_value_segment,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON l.l_suppkey = rs.s_suppkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = l.l_orderkey 
WHERE 
    rs.rank <= 5
GROUP BY 
    n.n_name, rs.s_name, hvc.c_name, hvc.c_acctbal, hvc.cust_value_segment
ORDER BY 
    n.n_name, total_revenue DESC;
