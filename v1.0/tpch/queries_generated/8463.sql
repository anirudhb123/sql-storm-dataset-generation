WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_name,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
FilteredOrders AS (
    SELECT ro.o_orderkey,
           ro.o_orderdate,
           ro.o_totalprice,
           ro.c_name
    FROM RankedOrders ro
    WHERE ro.rank_order <= 5
),
SupplierParts AS (
    SELECT ps.ps_partkey,
           s.s_name AS supplier_name,
           p.p_name AS part_name,
           ps.ps_availqty,
           ps.ps_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AggregatedResults AS (
    SELECT fo.o_orderkey,
           fo.o_orderdate,
           fo.o_totalprice,
           sp.part_name,
           sp.supplier_name,
           SUM(sp.ps_availqty) AS total_availqty,
           SUM(sp.ps_supplycost) AS total_supplycost
    FROM FilteredOrders fo
    JOIN SupplierParts sp ON sp.ps_partkey IN (SELECT l.l_partkey
                                                FROM lineitem l
                                                WHERE l.l_orderkey = fo.o_orderkey)
    GROUP BY fo.o_orderkey, fo.o_orderdate, fo.o_totalprice, sp.part_name, sp.supplier_name
)
SELECT ar.o_orderkey,
       ar.o_orderdate,
       ar.o_totalprice,
       ar.part_name,
       ar.supplier_name,
       ar.total_availqty,
       ar.total_supplycost,
       ROUND(ar.total_availqty * ar.total_supplycost, 2) AS total_cost_value
FROM AggregatedResults ar
ORDER BY ar.o_orderdate DESC, ar.o_totalprice DESC;
