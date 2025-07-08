WITH RECURSIVE CTE_Supplier AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) * 0.5 FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, cs.level + 1
    FROM supplier s
    JOIN CTE_Supplier cs ON s.s_nationkey = cs.s_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    ) AND cs.level < 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        os.total_revenue,
        os.part_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY os.total_revenue DESC) AS rn
    FROM orders o
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    WHERE o.o_totalprice > 10000
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(s.s_acctbal) AS total_supplier_balance,
    AVG(hvo.o_totalprice) AS average_order_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN HighValueOrders hvo ON c.c_custkey = hvo.o_orderkey
WHERE c.c_acctbal IS NOT NULL
AND s.s_acctbal > 1000
GROUP BY r.r_name
ORDER BY total_supplier_balance DESC
LIMIT 10;