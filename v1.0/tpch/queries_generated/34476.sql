WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 50000
),
RichCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) * 1.5 FROM customer c2
    )
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT rc.c_custkey) AS total_rich_customers,
    MAX(s.s_name) AS top_supplier
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
LEFT JOIN SupplierParts sp ON l.l_partkey = sp.ps_partkey AND l.l_suppkey = sp.ps_suppkey
LEFT JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
JOIN RichCustomers rc ON c.c_custkey = rc.c_custkey
WHERE l.l_shipdate > '2022-01-01'
AND l.l_returnflag = 'N'
GROUP BY r.r_name
HAVING total_revenue > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        GROUP BY o.o_orderkey
    ) AS subquery
) AND MAX(sh.level) IS NOT NULL
ORDER BY total_revenue DESC;
