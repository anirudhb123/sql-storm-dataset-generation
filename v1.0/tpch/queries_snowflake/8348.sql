WITH RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),
SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    ORDER BY ss.total_sales DESC
    LIMIT 10
)
SELECT 
    rs.r_name,
    ts.s_name,
    ts.total_sales
FROM RegionStats rs
JOIN TopSuppliers ts ON ts.s_suppkey IN (
    SELECT s.s_suppkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey = (
        SELECT r.r_regionkey
        FROM region r
        WHERE r.r_name = rs.r_name
    )
)
ORDER BY rs.r_name, ts.total_sales DESC;
