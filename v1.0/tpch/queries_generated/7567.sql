WITH CustomerOrderCounts AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY total_revenue DESC
    LIMIT 5
)
SELECT crc.c_custkey, crc.c_name, COALESCE(coc.order_count, 0) AS total_orders,
       psc.total_supply_cost, tr.total_revenue
FROM CustomerOrderCounts coc
JOIN customer crc ON coc.c_custkey = crc.c_custkey
JOIN PartSupplierCosts psc ON psc.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
LEFT JOIN TopRegions tr ON tr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = crc.c_nationkey)
WHERE coc.order_count > 0
ORDER BY tr.total_revenue DESC, total_orders DESC;
