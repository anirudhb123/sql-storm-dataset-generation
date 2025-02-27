
WITH RevenueBySupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        rb.total_revenue
    FROM 
        RevenueBySupplier rb
    JOIN 
        supplier s ON rb.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    ORDER BY 
        rb.total_revenue DESC
    LIMIT 10
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    ts.r_name AS region, 
    ts.total_revenue 
FROM 
    TopSuppliers ts
LEFT JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = ts.r_name)))
WHERE 
    o.o_orderstatus = 'F'
ORDER BY 
    ts.total_revenue DESC, ts.s_name;
