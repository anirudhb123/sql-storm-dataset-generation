WITH RECURSIVE CustomerChain AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_name LIKE 'A%'

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, cc.level + 1
    FROM customer c
    JOIN CustomerChain cc ON c.c_nationkey = cc.c_nationkey
    WHERE cc.level < 5
),
TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_supplycost DESC
    LIMIT 5
)
SELECT 
    cc.c_custkey,
    cc.c_name,
    ts.n_name AS nation,
    ts.total_supplycost,
    COALESCE(ts.total_supplycost, 0) / NULLIF(COUNT(ts.total_supplycost), 0) AS avg_supplycost
FROM CustomerChain cc
LEFT JOIN TotalSales t ON cc.c_custkey = t.o_custkey
RIGHT JOIN TopNations ts ON ts.n_nationkey = cc.c_nationkey
WHERE t.total_sales IS NOT NULL
  AND np.total_supplycost > 1000
ORDER BY avg_supplycost DESC;
