WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.custkey <> ch.custkey AND c.c_acctbal IS NOT NULL
),
OrderedTotal AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(li.l_quantity * (li.l_extendedprice * (1 - li.l_discount))) AS total
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
SupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)

SELECT 
    c.c_name,
    nh.r_name AS customer_nation,
    COALESCE(oh.total, 0) AS order_total,
    ss.total_available_qty,
    ROW_NUMBER() OVER (PARTITION BY nh.r_name ORDER BY COALESCE(oh.total, 0) DESC) AS rank
FROM customer c
JOIN nation nh ON c.c_nationkey = nh.n_nationkey
LEFT JOIN OrderedTotal oh ON c.c_custkey = oh.o_custkey
LEFT JOIN SupplierSummary ss ON ss.ps_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 5000
)
WHERE c.c_acctbal IS NOT NULL
ORDER BY customer_nation, rank
LIMIT 100;
