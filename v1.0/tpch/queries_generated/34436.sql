WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
),
OrderDetails AS (
    SELECT o.o_orderkey, 
           c.c_name AS customer_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
),
UnavailableParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty = 0
)
SELECT 
    ns.n_name AS nation_name,
    SUM(od.total_revenue) AS total_order_revenue,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS unavailable_parts,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN OrderDetails od ON s.s_suppkey = od.o_orderkey
LEFT JOIN UnavailableParts p ON s.s_suppkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE ns.n_name IS NOT NULL
GROUP BY ns.n_name
HAVING SUM(od.total_revenue) > 1000000
ORDER BY total_order_revenue DESC;
