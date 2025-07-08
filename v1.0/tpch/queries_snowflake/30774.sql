WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RegionalSales AS (
    SELECT n.n_name AS region_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
    GROUP BY n.n_name
),
PopularParts AS (
    SELECT p.p_name, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_name
    HAVING SUM(l.l_quantity) > 100
),
TopSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT 
    rh.region_name,
    ps.p_name,
    rh.total_sales,
    tp.s_name AS top_supplier,
    tp.total_cost
FROM RegionalSales rh
CROSS JOIN PopularParts ps
LEFT JOIN TopSuppliers tp ON tp.total_cost = (SELECT MAX(total_cost) FROM TopSuppliers)
WHERE rh.total_sales IS NOT NULL
ORDER BY rh.total_sales DESC, ps.total_quantity DESC;