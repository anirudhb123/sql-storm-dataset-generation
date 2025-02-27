WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY ss.order_count DESC) AS order_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.order_count, 0) AS order_count,
        rs.sales_rank,
        rs.order_rank
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.sales_rank <= 10 OR rs.order_rank <= 10
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_sales,
    ts.order_count
FROM 
    TopSuppliers ts
ORDER BY 
    ts.total_sales DESC, ts.order_count DESC;

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(c.c_acctbal) AS avg_acctbal
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON s.s_suppkey = c.c_nationkey
GROUP BY 
    n.n_name
HAVING 
    AVG(c.c_acctbal) IS NOT NULL
ORDER BY 
    customer_count DESC;

SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate IS NOT NULL 
    AND l.l_returnflag <> 'R'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
