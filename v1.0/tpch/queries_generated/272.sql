WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
FrequentBuyers AS (
    SELECT 
        c.c_custkey,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS order_rank
    FROM 
        CustomerOrders
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS frequent_customers,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '2023-01-01' 
    AND l.l_returnflag = 'N'
    AND p.p_size > 10
    AND EXISTS (
        SELECT 1 
        FROM RankedSuppliers rs 
        WHERE rs.s_suppkey = s.s_suppkey 
        AND rs.rank = 1
    )
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_revenue DESC;
