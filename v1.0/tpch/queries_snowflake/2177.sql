WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierCosts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
OuterJoinResult AS (
    SELECT p.p_name,
           p.p_brand,
           COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    LEFT JOIN SupplierCosts sc ON p.p_partkey = sc.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey AND o.o_orderstatus = 'O'
    GROUP BY p.p_name, p.p_brand, sc.total_supply_cost
)

SELECT r.r_name,
       SUM(oj.total_supply_cost) AS total_cost,
       COUNT(DISTINCT oj.p_name) AS part_count,
       MAX(oj.order_count) AS max_orders
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OuterJoinResult oj ON s.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_size > 10
    )
)
GROUP BY r.r_name
HAVING SUM(oj.total_supply_cost) > (
    SELECT AVG(total_supply_cost)
    FROM SupplierCosts
)
ORDER BY total_cost DESC;