WITH RECURSIVE CustomerRank AS (
    SELECT c_custkey, c_name, c_acctbal,
           DENSE_RANK() OVER (ORDER BY c_acctbal DESC) AS rank_value
    FROM customer
    WHERE c_acctbal IS NOT NULL
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
OrderOverview AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_tax) AS avg_tax,
           COUNT(DISTINCT l.l_orderkey) AS items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
      AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT c.c_name, s.s_name, o.total_sales, 
           p.p_name,
           CASE 
               WHEN o.total_sales > 1000 THEN 'High Value'
               WHEN o.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS sales_category,
           n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_name ORDER BY o.total_sales DESC) AS nation_rank
    FROM CustomerRank c
    CROSS JOIN NationSupplier n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN OrderOverview o ON c.c_custkey = o.o_orderkey
    LEFT JOIN PartStatistics p ON o.total_sales > p.avg_supplycost 
      AND p.total_available > 0
)
SELECT f.nation_name, f.c_name, f.s_name, f.total_sales, 
       f.sales_category, f.nation_rank
FROM FinalReport f
WHERE f.nation_rank <= 3
ORDER BY f.nation_name, f.sales_category DESC, f.total_sales DESC;
