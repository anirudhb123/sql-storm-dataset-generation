WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)
SELECT
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(c.c_acctbal) AS avg_customer_balance,
    SUM(os.total_sales) AS total_sales
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN CustomerRanked c ON c.rank <= 5
RIGHT OUTER JOIN OrderSummary os ON os.total_sales > 1000
GROUP BY r.r_name, n.n_name
HAVING SUM(os.item_count) > 10 AND COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY total_sales DESC, avg_customer_balance ASC;
