WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           o.o_orderstatus, 
           c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2023-12-31'
), TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus, ro.c_name
    FROM RankedOrders ro
    WHERE rank <= 5
), SupplierDetails AS (
    SELECT p.p_partkey, 
           s.s_suppkey, 
           s.s_name, 
           ps.ps_supplycost, 
           ps.ps_availqty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), OrderDetails AS (
    SELECT lo.l_orderkey, 
           lo.l_partkey, 
           lo.l_suppkey, 
           lo.l_quantity, 
           lo.l_extendedprice, 
           lo.l_discount, 
           lo.l_tax
    FROM lineitem lo
    JOIN TopOrders to ON lo.l_orderkey = to.o_orderkey
)
SELECT od.l_orderkey, 
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS revenue, 
       COUNT(DISTINCT sd.s_suppkey) AS supplier_count
FROM OrderDetails od
JOIN SupplierDetails sd ON od.l_suppkey = sd.s_suppkey
GROUP BY od.l_orderkey
HAVING SUM(od.l_extendedprice * (1 - od.l_discount)) > 10000
ORDER BY revenue DESC;
