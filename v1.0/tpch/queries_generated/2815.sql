WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
        INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        INNER JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2023-12-31'
        AND o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
        LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
        JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_spent,
    rs.s_name AS supplier_name,
    rs.total_sales,
    rs.order_count
FROM 
    CustomerOrders cs
    FULL OUTER JOIN RankedSuppliers rs ON cs.c_custkey = (SELECT MAX(c.c_custkey) FROM customer c WHERE cs.c_name LIKE CONCAT('%', rs.s_name, '%'))
WHERE 
    (rs.total_sales IS NOT NULL OR cs.total_spent IS NOT NULL)
ORDER BY 
    total_spent DESC NULLS LAST, 
    total_sales DESC NULLS LAST
LIMIT 100;
