WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) as part_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        ts.s_name,
        ts.part_count,
        ts.s_acctbal
    FROM 
        RankedSuppliers ts
    JOIN 
        nation n ON ts.rank = 1 AND ts.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)

SELECT 
    r.region,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount
FROM 
    TopSuppliers ts
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > ts.s_acctbal)
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    r.region
HAVING 
    total_revenue > 1000000
ORDER BY 
    total_revenue DESC;
