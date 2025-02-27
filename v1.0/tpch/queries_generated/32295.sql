WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RegionSales AS (
    SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    rs.total_sales,
    COALESCE(oh.total_spent, 0) AS customer_spending,
    p.total_available AS part_availability,
    sh.level AS supplier_level
FROM RegionSales rs
JOIN region r ON r.r_name = rs.r_name
LEFT JOIN OrderSummary oh ON oh.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_mktsegment = 'BUILDING'
)
LEFT JOIN PartSupplier p ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
)
JOIN SupplierHierarchy sh ON sh.s_suppkey = ANY (
    SELECT s.s_suppkey 
    FROM supplier s 
    WHERE s.s_acctbal BETWEEN 1000 AND 5000
)
ORDER BY rs.total_sales DESC, customer_spending DESC;
