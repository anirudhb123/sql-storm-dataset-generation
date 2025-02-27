WITH HighValueOrders AS (
    SELECT o_orderkey, o_totalprice, c_nationkey
    FROM orders
    JOIN customer ON o_custkey = c_custkey
    WHERE o_totalprice > (
        SELECT AVG(o_totalprice)
        FROM orders
    )
), SupplierPartDetails AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
), NationPartTotals AS (
    SELECT n.n_name, SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue
    FROM lineitem lp
    JOIN orders o ON lp.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY n.n_name
)
SELECT r.r_name, COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
       SUM(npt.total_revenue) AS total_revenue_by_nation,
       SUM(s.total_supply_cost) AS total_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN HighValueOrders hvo ON hvo.c_nationkey = n.n_nationkey
LEFT JOIN NationPartTotals npt ON npt.n_name = n.n_name
LEFT JOIN SupplierPartDetails s ON s.ps_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_availqty > 500
)
GROUP BY r.r_name
ORDER BY r.r_name;
