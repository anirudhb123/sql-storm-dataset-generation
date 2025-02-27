WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500 AND sh.hierarchy_level < 3
),

CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, SUM(ps.ps_availqty) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),

RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           RANK() OVER(PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_tax < 0.1
),

FinalReport AS (
    SELECT sh.s_name, c.c_name, count(DISTINCT o.o_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           p.p_name, p.total_available,
           ROW_NUMBER() OVER(ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM SupplierHierarchy sh
    JOIN customer c ON sh.s_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN PartSupplierInfo p ON l.l_partkey = p.p_partkey
    WHERE o.o_orderstatus <> 'F'
    GROUP BY sh.s_name, c.c_name, p.p_name, p.total_available
)

SELECT *
FROM FinalReport
WHERE total_orders > 0
ORDER BY revenue_rank ASC
LIMIT 10;
