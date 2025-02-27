WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),

Summary AS (
    SELECT n.n_name AS nation_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN orders o ON o.o_orderkey = l.l_orderkey
    GROUP BY n.n_name
)

SELECT DISTINCT
    sh.s_name,
    sh.level,
    c.c_name,
    coalesce(pd.total_supplycost, 0) AS total_supplycost,
    so.nation_name,
    so.total_sales
FROM SupplierHierarchy sh
JOIN CustomerOrders c ON c.order_count > 5
LEFT JOIN PartDetails pd ON pd.total_supplycost > (SELECT AVG(total_supplycost) FROM PartDetails) 
LEFT JOIN Summary so ON so.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = sh.s_nationkey)
WHERE sh.level < 3
ORDER BY sh.level, so.total_sales DESC;
