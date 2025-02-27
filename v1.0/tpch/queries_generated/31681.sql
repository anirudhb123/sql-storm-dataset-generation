WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
RegionStats AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    s.s_suppkey,
    s.s_name,
    sh.level,
    os.total_price,
    tc.total_spent,
    rs.nation_count
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
LEFT JOIN OrderSummary os ON os.total_price > 0
LEFT JOIN TopCustomers tc ON tc.total_spent > 10000 AND tc.total_spent < 50000
LEFT JOIN RegionStats rs ON rs.nation_count > 2
WHERE s.s_acctbal IS NOT NULL
ORDER BY sh.level, tc.total_spent DESC, os.total_price ASC
LIMIT 50;
