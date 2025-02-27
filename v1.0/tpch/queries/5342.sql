
WITH SupplierAggregates AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT nation.n_name, 
       SUM(CASE WHEN ca.order_count IS NOT NULL THEN ca.total_spent ELSE 0 END) AS total_spent_by_nation,
       COUNT(DISTINCT sa.s_suppkey) AS distinct_suppliers,
       SUM(sa.total_supply_cost) AS total_supply_cost
FROM nation 
LEFT JOIN CustomerOrders ca ON nation.n_nationkey = ca.c_custkey
LEFT JOIN SupplierAggregates sa ON nation.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ca.c_custkey LIMIT 1)
LEFT JOIN LineItemDetails li ON li.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ca.c_custkey LIMIT 1)
WHERE nation.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Asia')
GROUP BY nation.n_name
ORDER BY total_spent_by_nation DESC, distinct_suppliers DESC;
