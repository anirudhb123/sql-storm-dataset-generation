WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate > '2022-01-01')
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 100
),
CustomerRegions AS (
    SELECT c.c_custkey, n.n_name AS nation, r.r_name AS region
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
       COALESCE(MAX(l.l_extendedprice), 0) AS max_extended_price,
       COALESCE(AVG(l.l_discount), 0) AS avg_discount,
       STRING_AGG(DISTINCT r.region, ', ') AS regions
FROM customer c
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN CustomerRegions r ON c.c_custkey = r.c_custkey
WHERE c.c_acctbal IS NOT NULL
  AND c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
  AND NOT EXISTS (SELECT 1 FROM TopSuppliers ts WHERE ts.ps_suppkey = l.l_suppkey)
  AND o.o_orderdate IS NOT NULL
GROUP BY c.c_custkey, c.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
   AND MAX(l.l_discount) < 0.05
ORDER BY order_count DESC, max_extended_price DESC
LIMIT 10;
