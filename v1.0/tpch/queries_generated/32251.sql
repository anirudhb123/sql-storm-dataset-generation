WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_linenumber) AS line_items_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2023-01-01'
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT TOP 10
    ph.p_name,
    ph.p_retailprice,
    COALESCE(cs.customer_rank, 0) AS customer_rank,
    sr.supplier_count,
    os.total_sales,
    RANK() OVER (PARTITION BY sr.supplier_count ORDER BY os.total_sales DESC) AS sales_rank
FROM part ph
LEFT JOIN TopCustomers cs ON ph.p_partkey IN (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT sh.s_suppkey FROM SupplierHierarchy sh))
LEFT JOIN NationRegion sr ON ph.p_partkey IN (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey IN (SELECT n_nationkey FROM nation n WHERE n.n_name = sr.n_name)))
LEFT JOIN OrderStatistics os ON ph.p_partkey = os.o_orderkey
WHERE ph.p_retailprice IS NOT NULL AND ph.p_container LIKE 'SM%'
ORDER BY sales_rank;
