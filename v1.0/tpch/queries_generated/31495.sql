WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_address, c.c_nationkey, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000.00

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_address, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 2
),
TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerSales AS (
    SELECT ch.c_custkey, ch.c_name, ts.total_spent, ch.level,
           RANK() OVER (PARTITION BY ch.level ORDER BY ts.total_spent DESC) AS rank
    FROM CustomerHierarchy ch
    LEFT JOIN TotalSales ts ON ch.c_custkey = ts.o_custkey
)
SELECT cs.c_custkey, cs.c_name, COALESCE(cs.total_spent, 0) AS total_spent,
       CASE WHEN cs.total_spent IS NULL THEN 'No Orders' 
            ELSE 'Regular Customer' 
       END AS customer_status,
       r.r_name AS region_name
FROM CustomerSales cs
LEFT JOIN nation n ON cs.c_custkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE cs.rank <= 5 OR cs.rank IS NULL
ORDER BY cs.level, cs.total_spent DESC;

