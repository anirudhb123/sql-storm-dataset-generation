WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_name, supplier_revenue,
           RANK() OVER (ORDER BY supplier_revenue DESC) AS supplier_rank
    FROM SupplierPerformance
),
RegionData AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT oh.o_orderkey, oh.o_orderdate, cs.c_name, cs.total_sales,
       ts.s_name AS top_supplier, ts.supplier_revenue,
       rd.nation_name, rd.region_name, rd.total_suppliers
FROM OrderHierarchy oh
LEFT JOIN CustomerSales cs ON oh.o_orderkey = cs.c_custkey
LEFT JOIN TopSuppliers ts ON ts.supplier_rank <= 10
JOIN RegionData rd ON rd.total_suppliers > 0
WHERE oh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
  AND cs.total_sales IS NOT NULL
ORDER BY oh.o_orderdate DESC, cs.total_sales DESC;
