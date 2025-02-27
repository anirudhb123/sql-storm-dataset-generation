WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_name,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           n.n_name AS nation,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS supply_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000
),
HighValueLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01'
    GROUP BY l.l_orderkey
)
SELECT ro.o_orderkey,
       ro.o_orderdate,
       ro.o_totalprice,
       ro.c_name,
       sd.s_name AS supplier_name,
       sd.nation,
       hv.total_value AS line_item_value
FROM RankedOrders ro
LEFT JOIN SupplierDetails sd ON sd.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                             FROM lineitem l 
                             WHERE l.l_orderkey = ro.o_orderkey) 
    ORDER BY ps.ps_supplycost ASC 
    LIMIT 1
)
LEFT JOIN HighValueLineItems hv ON hv.l_orderkey = ro.o_orderkey
WHERE ro.order_rank = 1
  AND (hv.total_value IS NULL OR hv.total_value > 10000)
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;
