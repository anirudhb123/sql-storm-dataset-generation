WITH RECURSIVE CustomerOrderCTE AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
),
PartSupplierCTE AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentHighValueOrders AS (
    SELECT DISTINCT o.o_orderkey, o.o_totalprice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.15
    AND l.l_shipdate >= '2023-01-01'
),
RegionSupplier AS (
    SELECT n.n_nationkey, r.r_regionkey, COUNT(s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_regionkey
    HAVING COUNT(s.s_suppkey) > 5
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
       ps.total_availqty, ps.avg_supplycost, r.supplier_count
FROM CustomerOrderCTE co
LEFT JOIN PartSupplierCTE ps ON co.o_orderkey IN (
    SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 500
    )
)
LEFT JOIN RecentHighValueOrders rhvo ON co.o_orderkey = rhvo.o_orderkey
LEFT JOIN RegionSupplier r ON co.c_custkey IN (
    SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (
        SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey
    )
)
WHERE (co.rn <= 10 AND r.supplier_count IS NOT NULL)
AND (co.o_totalprice IS NOT NULL OR co.o_orderdate IS NOT NULL)
ORDER BY co.o_orderdate DESC, ps.avg_supplycost DESC;
