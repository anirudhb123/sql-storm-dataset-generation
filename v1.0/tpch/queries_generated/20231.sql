WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS lev
    FROM nation n
    UNION ALL
    SELECT nh.n_nationkey, nh.n_name, nh.n_regionkey, lev + 1
    FROM NationHierarchy nh
    JOIN nation n ON nh.n_regionkey = n.n_nationkey
    WHERE lev < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_availqty) AS total_availqty,
           AVG(s.s_acctbal) OVER (PARTITION BY s.s_nationkey) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummaries AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderstatus) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerRanks AS (
    SELECT c.c_custkey, c.c_name,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name AS nation_name, s.s_name AS supplier_name,
       cs.c_name AS customer_name, osc.total_order_value,
       ss.total_availqty, ss.avg_acctbal,
       RANK() OVER (PARTITION BY n.n_nationkey ORDER BY osc.total_order_value DESC) AS value_rank
FROM NationHierarchy n
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
JOIN OrderSummaries osc ON ss.s_suppkey = osc.o_orderkey
JOIN CustomerRanks cs ON osc.o_orderkey = cs.c_custkey
WHERE ss.total_availqty IS NOT NULL
  AND osc.total_order_value > (SELECT AVG(total_order_value) FROM OrderSummaries)
ORDER BY n.n_name, value_rank
OPTION (RECOMPILE);
