WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, cte.level + 1
    FROM customer c
    JOIN CustomerCTE cte ON c.c_nationkey = cte.c_custkey
    WHERE c.c_acctbal > cte.c_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierPart AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TotalStats AS (
    SELECT
        p.p_partkey,
        AVG(COALESCE(s.total_supplycost, 0)) AS avg_supplycost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    LEFT JOIN SupplierPart s ON p.p_partkey = s.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey 
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name,
    ns.n_name,
    SUM(os.net_sales) AS total_net_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(ts.order_count) AS max_orders
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey 
LEFT JOIN customer c ON ns.n_nationkey = c.c_nationkey
JOIN OrderSummary os ON os.o_orderdate > '2023-01-01'
LEFT JOIN TotalStats ts ON ts.p_partkey IN (
    SELECT p.p_partkey FROM part p WHERE p.p_size > 10
)
GROUP BY r.r_name, ns.n_name
HAVING SUM(os.net_sales) > 10000
ORDER BY total_net_sales DESC;
