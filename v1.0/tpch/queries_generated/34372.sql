WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal > (
        SELECT AVG(c_acctbal) FROM customer
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, cte.level + 1
    FROM customer c
    JOIN CustomerCTE cte ON c.c_nationkey = cte.c_nationkey
    WHERE c.custkey <> cte.c_custkey AND level < 3
),
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_partkey) AS lineitem_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
TopOrders AS (
    SELECT o.o_custkey, SUM(o.total_sales) AS customer_total_sales
    FROM OrderStats o
    WHERE o.sales_rank <= 5
    GROUP BY o.o_custkey
)
SELECT c.c_name, c.acctbal, ns.n_name, ns.supplier_count, ns.total_acctbal, 
       (SELECT COUNT(*) FROM TopOrders WHERE o_custkey = c.c_custkey) AS order_count,
       RANK() OVER (PARTITION BY ns.n_name ORDER BY c.c_acctbal DESC) AS rank_within_nation
FROM customer c
JOIN CustomerCTE cte ON c.c_custkey = cte.c_custkey
LEFT JOIN NationStats ns ON c.c_nationkey = ns.n_nationkey
WHERE c.c_acctbal IS NOT NULL AND c.c_name IS NOT NULL
ORDER BY ns.n_name, c.c_acctbal DESC;
