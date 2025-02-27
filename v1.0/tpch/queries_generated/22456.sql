WITH RegionSuppliers AS (
    SELECT r.r_regionkey, r.r_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 0
), 
TopSuppliers AS (
    SELECT r_regionkey, AVG(s_acctbal) AS avg_acctbal
    FROM RegionSuppliers
    GROUP BY r_regionkey
    HAVING COUNT(*) > 1
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), 
JoinLineItems AS (
    SELECT lo.o_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           COALESCE(NULLIF(ROUND(l.l_extendedprice * (1 - l.l_discount), 2), 0), NULL) AS effective_price
    FROM lineitem l
    JOIN orders lo ON l.l_orderkey = lo.o_orderkey
    WHERE l.l_returnflag = 'N'
)

SELECT r.r_name, 
       SUM(COALESCE(lo.l_quantity, 0)) AS total_quantity,
       COUNT(DISTINCT lo.o_orderkey) AS number_of_orders,
       AVG(ts.avg_acctbal) AS avg_supplier_acctbal,
       MAX(lo.effective_price) AS max_effective_order_price,
       STRING_AGG(DISTINCT su.s_name, ', ') AS supplier_names
FROM JoinLineItems lo
JOIN RegionSuppliers su ON lo.o_orderkey IN (
    SELECT o_orderkey FROM CustomerOrders WHERE order_rank = 1
)
LEFT JOIN TopSuppliers ts ON su.r_regionkey = ts.r_regionkey
JOIN region r ON su.r_regionkey = r.r_regionkey
GROUP BY r.r_name
HAVING SUM(lo.l_quantity) > (SELECT AVG(l_quantity) FROM JoinLineItems)
   AND COUNT(DISTINCT lo.o_orderkey) > 5
ORDER BY total_quantity DESC, number_of_orders DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
