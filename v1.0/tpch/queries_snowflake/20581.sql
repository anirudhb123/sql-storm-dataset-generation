
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1, s.s_nationkey, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.lvl < 5
),
FrequentOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > DATEADD(year, -1, '1998-10-01')
    GROUP BY o.o_custkey
    HAVING COUNT(o.o_orderkey) > (
        SELECT AVG(order_count)
        FROM (
            SELECT COUNT(o2.o_orderkey) AS order_count
            FROM orders o2
            GROUP BY o2.o_custkey
        ) AS sub
    )
),
TopSuppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    ORDER BY total_supplycost DESC
    LIMIT 10
)
SELECT p.p_name, p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       LISTAGG(DISTINCT n.n_name, ',') WITHIN GROUP (ORDER BY n.n_name) AS supplier_nations
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN FrequentOrders fo ON o.o_custkey = fo.o_custkey
LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
WHERE (p.p_retailprice IS NOT NULL OR p.p_container IS NULL)
  AND (s.s_acctbal > 0 OR s.s_name IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue
        FROM part p2
        JOIN lineitem l2 ON p2.p_partkey = l2.l_partkey
        GROUP BY p2.p_partkey
    ) AS subquery
) OR COUNT(DISTINCT n.n_name) > 1;
