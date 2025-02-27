WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
),
TotalLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2022-01-01'
    GROUP BY o.o_orderkey
),
PartSupplies AS (
    SELECT p.p_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    COALESCE(th.total_line_items, 0) AS total_line_items,
    COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
    sh.level AS supplier_level,
    SUM(ps.total_avail_qty * COALESCE(th.total_line_items, 0) / NULLIF(ps.total_avail_qty, 0)) AS performance_metric
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN TotalLineItems th ON c.c_custkey = th.o_orderkey
JOIN PartSupplies ps ON ps.p_name LIKE '%' || SUBSTRING(c.c_name FROM 1 FOR 3) || '%'
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_suppkey
GROUP BY 
    r.r_name, n.n_name, c.c_name, sh.level
ORDER BY performance_metric DESC
LIMIT 10;
