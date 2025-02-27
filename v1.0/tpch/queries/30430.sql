
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 
           CAST(s_suppkey AS VARCHAR(255)) AS path
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CONCAT(sh.path, ' -> ', s.s_suppkey)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(MIN(l.l_shipdate), DATE '9999-12-31') AS earliest_ship_date,
    ns.n_name AS nation_name,
    ns.customer_count,
    ROUND(AVG(l.l_discount), 2) AS average_discount,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     WHERE o.o_orderdate > DATE '1998-10-01' - INTERVAL '30 days') AS recent_order_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN NationDetails ns ON s.s_nationkey = ns.n_nationkey
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ns.n_name, ns.customer_count
HAVING SUM(l.l_quantity) > 100 OR MIN(l.l_shipdate) < DATE '1998-10-01' - INTERVAL '10 days'
ORDER BY total_quantity DESC, p.p_name ASC
LIMIT 50;
