
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
PartSupplierInfo AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT ro.o_orderkey,
       ro.o_orderdate,
       ro.o_totalprice,
       psi.p_partkey,
       psi.p_name,
       psi.total_supply_cost,
       psi.supplier_count
FROM RankedOrders ro
LEFT JOIN PartSupplierInfo psi ON psi.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = ro.o_orderkey
    AND l.l_returnflag = 'N'
)
WHERE ro.rank <= 10
AND (ro.o_totalprice - COALESCE(psi.total_supply_cost, 0)) > 100
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;
