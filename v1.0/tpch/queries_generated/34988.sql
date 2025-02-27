WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, s.s_acctbal, 1 AS lvl
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, s.s_acctbal, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.nationkey
    WHERE sh.lvl < 5
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT l.l_partkey) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerRanking AS (
    SELECT c.c_custkey, c.c_name, os.total_revenue, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
), HighValueCustomers AS (
    SELECT c.*, hv.total_revenue
    FROM customer c
    JOIN CustomerRanking hv ON c.c_custkey = hv.c_custkey
    WHERE hv.revenue_rank <= 5
), ProductDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_size, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    COALESCE(hvc.total_revenue, 0) AS high_value_customer_revenue,
    pd.p_name AS product_name,
    pd.total_cost AS product_total_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN HighValueCustomers hvc ON sh.s_suppkey = hvc.c_custkey
JOIN ProductDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
WHERE r.r_comment IS NOT NULL
AND pd.total_cost > 1000
ORDER BY r.r_name, n.n_name, sh.s_name, pd.total_cost DESC;
