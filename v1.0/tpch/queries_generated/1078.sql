WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
HighValueLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity,
           l.l_extendedprice * (1 - l.l_discount) AS net_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS line_item_rank
    FROM lineitem l
    WHERE l.l_tax > 0.05
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(hv.net_price) AS total_revenue
    FROM orders o
    JOIN HighValueLineItems hv ON o.o_orderkey = hv.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, SUM(os.total_revenue) AS region_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
WHERE rs.rn = 1
GROUP BY r.r_name
ORDER BY region_revenue DESC;
