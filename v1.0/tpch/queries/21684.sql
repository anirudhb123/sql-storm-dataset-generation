WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS full_name, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 500000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(CONCAT(sh.full_name, ' -> ', s.s_name) AS VARCHAR(100)), 
           level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%metal%')
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighestRevenuePerCustomer AS (
    SELECT o.o_custkey, 
           MAX(os.total_revenue) AS max_revenue
    FROM orders o
    JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY o.o_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(sh.s_acctbal) AS total_supplier_balance,
    AVG(d.total_revenue) AS avg_department_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(COALESCE(re.max_revenue, 0)) AS largest_revenue
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON true
LEFT JOIN PartDetails p ON p.rank <= 10
LEFT JOIN HighestRevenuePerCustomer re ON re.o_custkey = c.c_custkey
JOIN OrderSummary d ON c.c_custkey = d.o_orderkey
GROUP BY n.n_name, r.r_name
HAVING SUM(sh.s_acctbal) > 1000000
ORDER BY customer_count DESC, total_supplier_balance DESC NULLS LAST;
