WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalOrders AS (
    SELECT o_custkey, COUNT(*) AS total_orders
    FROM orders
    GROUP BY o_custkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COALESCE(to.total_orders, 0) AS total_orders
    FROM customer c
    LEFT JOIN TotalOrders to ON c.c_custkey = to.o_custkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT cs.c_name, cs.c_acctbal,
       COUNT(DISTINCT lo.l_orderkey) AS total_line_items,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
       AVG(CASE WHEN lo.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS avg_returned_value,
       MAX(hvp.total_value) AS max_part_value,
       MAX(CASE WHEN ro.price_rank <= 10 THEN ro.o_totalprice ELSE NULL END) AS top_order_price
FROM CustomerSummary cs
JOIN lineitem l ON cs.c_custkey = l.l_orderkey
LEFT JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN HighValueParts hvp ON hvp.p_partkey = l.l_partkey
LEFT JOIN lineitem lo ON cs.c_custkey = lo.l_orderkey
GROUP BY cs.c_custkey, cs.c_name, cs.c_acctbal
HAVING SUM(l.l_extendedprice) > 50000
ORDER BY cs.c_acctbal DESC;
