WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > co.o_totalprice
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
),
RankedOrders AS (
    SELECT co.c_custkey, co.o_orderkey, co.o_totalprice,
           RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.o_totalprice DESC) AS price_rank
    FROM CustomerOrders co
)
SELECT nr.r_name, nr.n_name, SUM(ss.avg_supplycost) AS total_avg_supplycost, COUNT(DISTINCT ro.o_orderkey) AS total_orders,
       AVG(ro.o_totalprice) AS avg_order_value
FROM NationRegion nr
LEFT JOIN SupplierStats ss ON nr.supplier_count > 0
LEFT JOIN RankedOrders ro ON nr.n_name = (SELECT n.n_name FROM nation n JOIN customer c ON n.n_nationkey = c.c_nationkey WHERE c.c_custkey = ro.c_custkey LIMIT 1)
WHERE ss.avg_supplycost IS NOT NULL
GROUP BY nr.r_name, nr.n_name
HAVING COUNT(ro.o_orderkey) > 5
ORDER BY total_avg_supplycost DESC, nr.r_name;
