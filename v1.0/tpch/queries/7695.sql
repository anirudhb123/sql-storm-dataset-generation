
WITH NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(ps.ps_availqty) AS total_available_quantity, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(ns.total_supply_cost) AS region_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationStats ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY region_supply_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
LineitemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, tr.r_name, co.c_name, co.order_count, co.total_spent,
       ld.total_revenue, ld.last_ship_date
FROM NationStats ns
JOIN TopRegions tr ON ns.total_supply_cost IN (SELECT region_supply_cost FROM TopRegions)
JOIN CustomerOrders co ON ns.total_available_quantity > co.order_count
JOIN LineitemDetails ld ON ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
ORDER BY ns.n_name, tr.r_name, co.total_spent DESC;
