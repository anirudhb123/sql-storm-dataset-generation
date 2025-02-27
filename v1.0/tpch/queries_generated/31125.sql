WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        WHERE s2.s_nationkey = s.s_nationkey
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
),
CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM partsupp ps
    INNER JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name, 
    r.r_name AS region, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(p.r_retailprice * pc.order_count), 0) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY total_revenue DESC) AS revenue_rank
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN CustomerPurchases c ON sh.s_nationkey = c.c_nationkey
LEFT JOIN PartCount pc ON ps.ps_partkey = pc.ps_partkey
JOIN region r ON sh.s_nationkey = r.r_regionkey
WHERE p.p_size BETWEEN 10 AND 20
AND r.r_name IS NOT NULL
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING customer_count > 10
ORDER BY total_revenue DESC, region ASC;
