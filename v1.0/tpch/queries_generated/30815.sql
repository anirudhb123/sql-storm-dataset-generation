WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT sc.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.ps_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0 AND sc.s_suppkey <> s.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_revenue) AS customer_revenue
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, SUM(cr.customer_revenue) AS total_revenue_by_region
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN SupplyChain sc ON ps.ps_partkey = sc.ps_partkey
LEFT JOIN CustomerRevenue cr ON sc.s_suppkey = cr.c_custkey
WHERE ps.ps_supplycost > (
        SELECT AVG(ps2.ps_supplycost)
        FROM partsupp ps2
        WHERE ps2.ps_availqty < 100
    )
GROUP BY r.r_name
ORDER BY total_revenue_by_region DESC
LIMIT 10;
