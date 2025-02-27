WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
OrderStats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS total_lines, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
CustomerRanked AS (
    SELECT c.*, RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS acctbal_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
FinalSelection AS (
    SELECT DISTINCT r.r_name, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_orders, AVG(l.l_discount) AS avg_discount
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE r.r_name LIKE 'E%'
    GROUP BY r.r_name, n.n_name
)
SELECT s.s_name, th.total_supply_cost, COUNT(DISTINCT os.o_orderkey) AS total_orders,
    AVG(cs.acctbal_rank) AS avg_customer_rank, fs.customer_count,
    fs.total_orders, fs.avg_discount
FROM TopSuppliers th
JOIN SupplierHierarchy sh ON th.s_suppkey = sh.s_suppkey
LEFT JOIN OrderStats os ON os.total_lines > 5
LEFT JOIN CustomerRanked cs ON cs.c_custkey = os.o_orderkey
LEFT JOIN FinalSelection fs ON fs.total_orders > 100
WHERE sh.level <= 3
  AND th.total_supply_cost IS NOT NULL
GROUP BY s.s_name, th.total_supply_cost, fs.customer_count
HAVING COUNT(DISTINCT os.o_orderkey) > 2
ORDER BY th.total_supply_cost DESC, fs.customer_count ASC;
