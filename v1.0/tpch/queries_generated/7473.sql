WITH RECURSIVE SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_availqty, ps.ps_supplycost, 1 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_availqty, ps.ps_supplycost, sc.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierChain sc ON sc.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0 AND sc.level < 5
),
RegionalSales AS (
    SELECT n.n_name AS region_name, SUM(o.o_totalprice) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT sc.s_suppkey, sc.s_name, rs.region_name, rs.total_sales, ts.total_cost
FROM SupplierChain sc
JOIN RegionalSales rs ON rs.region_name = (
    SELECT n.n_name
    FROM nation n
    WHERE n.n_nationkey = sc.s_nationkey
)
JOIN TopSuppliers ts ON sc.s_suppkey = ts.s_suppkey
ORDER BY rs.total_sales DESC, ts.total_cost ASC;
