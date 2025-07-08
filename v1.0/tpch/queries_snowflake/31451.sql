WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL 
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT ol.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_lineitem_price
    FROM orders ol
    JOIN lineitem li ON ol.o_orderkey = li.l_orderkey
    GROUP BY ol.o_orderkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT nh.n_name, co.c_name, co.total_orders, co.total_spent, r.supplier_rank
FROM NationHierarchy nh
JOIN CustomerOrders co ON nh.n_nationkey = co.c_custkey
LEFT JOIN RankedSuppliers r ON co.total_orders > 5 AND r.total_cost IS NOT NULL
WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders WHERE total_orders > 5)
ORDER BY nh.level, co.total_spent DESC
LIMIT 100;
