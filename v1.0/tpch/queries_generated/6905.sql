WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
), 
TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, c.c_name, c.c_nationkey
    FROM RankedOrders ro
    JOIN customer c ON ro.o_orderkey = c.c_custkey
    WHERE ro.rn <= 5
), 
SupplierDetails AS (
    SELECT ps.ps_partkey, s.s_name, s.s_acctbal, p.p_retailprice, 
           SUM(l.l_quantity) AS total_quantity
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, s.s_name, s.s_acctbal, p.p_retailprice
), 
FinalReport AS (
    SELECT to.o_orderkey, to.o_orderdate, to.o_totalprice, 
           sd.s_name, sd.s_acctbal, sd.p_retailprice, 
           sd.total_quantity, c.c_nationkey
    FROM TopOrders to
    JOIN SupplierDetails sd ON to.o_orderkey = sd.ps_partkey
    JOIN customer c ON to.c_nationkey = c.c_nationkey
)
SELECT f.o_orderkey, f.o_orderdate, f.o_totalprice, 
       f.s_name, f.s_acctbal, f.p_retailprice, 
       f.total_quantity, r.r_name
FROM FinalReport f
JOIN nation n ON f.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
ORDER BY f.o_orderdate DESC, f.total_quantity DESC;
