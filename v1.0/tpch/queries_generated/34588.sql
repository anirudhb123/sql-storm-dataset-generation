WITH RECURSIVE SuppHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SuppHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
CustomerWithMaxOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) = (
        SELECT MAX(order_count) 
        FROM (SELECT COUNT(o.o_orderkey) AS order_count
              FROM customer c_inner
              LEFT JOIN orders o ON c_inner.c_custkey = o.o_custkey
              GROUP BY c_inner.c_custkey) AS order_counts
    )
)
SELECT C.c_name AS customer_name, C.order_count, O.price_rank, P.p_name AS part_name,
       S.s_name AS supplier_name, S.Level AS supplier_level
FROM CustomerWithMaxOrders C
JOIN RankedOrders O ON C.c_custkey = O.o_custkey
LEFT JOIN PartSupplier P ON O.o_orderkey = P.p_partkey
LEFT JOIN SuppHierarchy S ON P.p_partkey = S.s_suppkey
WHERE C.order_count > 5 AND (C.order_count IS NOT NULL) 
ORDER BY O.price_rank, C.order_count DESC, S.Level ASC;
