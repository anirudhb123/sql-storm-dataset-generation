WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.num_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM
        SupplierSales s
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales
    FROM 
        RankedSales s
    WHERE 
        s.sales_rank <= 5
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(hv.total_sales, 0) AS high_value_supplier_sales
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    HighValueSuppliers hv ON hv.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_type LIKE 'SMALL%'
    )
WHERE 
    n.n_regionkey IN (
        SELECT r.r_regionkey
        FROM region r
        WHERE r.r_name = 'AMERICA'
    )
GROUP BY 
    n.n_name
ORDER BY 
    n.n_name;
