WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT s.*, 
           RANK() OVER (PARTITION BY region.r_name ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT rs.s_suppkey, rs.s_name, COALESCE(rs.total_sales, 0) AS total_sales, COALESCE(rs.total_orders, 0) AS total_orders, rs.sales_rank
FROM RankedSuppliers rs
WHERE rs.sales_rank <= 3
ORDER BY rs.sales_rank ASC, total_sales DESC;

-- Additional Info: Include part details for the top suppliers based on sales
SELECT p.p_partkey, p.p_name, p.p_brand, ss.total_sales
FROM part p
JOIN SupplierSales ss ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey IN (
        SELECT s.s_suppkey
        FROM SupplierSales s
        ORDER BY s.total_sales DESC
        LIMIT 10
    )
)
ORDER BY ss.total_sales DESC;
