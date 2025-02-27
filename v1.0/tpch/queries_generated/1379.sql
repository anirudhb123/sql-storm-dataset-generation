WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2022-01-01'
        AND l.l_shipdate < '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS rank
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(o.o_totalprice) AS total_spent,
    COALESCE(ts.rank, 0) AS supplier_rank
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    (
        SELECT DISTINCT
            s.s_suppkey,
            ts.rank
        FROM 
            TopSuppliers ts
        JOIN 
            partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    ) ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    SUM(o.o_totalprice) > 1000
ORDER BY 
    total_spent DESC;
