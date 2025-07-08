
WITH SupplierAggregate AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availqty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_linenumber) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acctbal_rank
    FROM customer c
)
SELECT r.r_name, 
       COALESCE(AVG(sa.total_supplycost), 0) AS avg_supplycost,
       COALESCE(SUM(os.total_order_value), 0) AS total_order_value,
       SUM(CASE WHEN cr.acctbal_rank <= 3 THEN 1 ELSE 0 END) AS top_customers_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierAggregate sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN OrderSummary os ON os.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN CustomerRanked cr ON cr.c_custkey = os.o_custkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY r.r_name;
