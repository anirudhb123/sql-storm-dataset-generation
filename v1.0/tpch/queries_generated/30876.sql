WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
),
OrderSummaries AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit,
           COUNT(DISTINCT c.c_custkey) AS cust_count,
           CASE 
               WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 THEN 'High Value'
               ELSE 'Low Value'
           END AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, SUM(os.total_profit) AS total_profit,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       STRING_AGG(DISTINCT pp.p_name, ', ') AS popular_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN OrderSummaries os ON s.s_suppkey = os.cust_count
LEFT JOIN RankedParts pp ON pp.rank <= 3
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(os.total_profit) IS NOT NULL
ORDER BY total_profit DESC;
