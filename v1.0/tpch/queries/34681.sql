WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
TopRegions AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
    ORDER BY nation_count DESC
    LIMIT 5
),
CustomerStats AS (
    SELECT c.c_custkey, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)

SELECT 
    pp.p_partkey,
    pp.p_name,
    SUM(ps.ps_availqty) AS total_available,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COALESCE(cs.avg_order_value, 0) AS average_customer_order_value,
    th.r_name,
    th.nation_count,
    sh.level AS supplier_level
FROM part pp
LEFT JOIN partsupp ps ON pp.p_partkey = ps.ps_partkey
LEFT JOIN CustomerStats cs ON cs.c_custkey = (SELECT MAX(c.c_custkey) FROM customer c WHERE c.c_acctbal < pp.p_retailprice)
LEFT JOIN TopRegions th ON th.r_name = (SELECT MIN(r.r_name) FROM region r)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT MAX(s.s_suppkey) FROM supplier s WHERE s.s_acctbal > 2000)
GROUP BY pp.p_partkey, pp.p_name, cs.avg_order_value, th.r_name, th.nation_count, sh.level
HAVING SUM(ps.ps_availqty) > 0
ORDER BY total_available DESC, pp.p_name;