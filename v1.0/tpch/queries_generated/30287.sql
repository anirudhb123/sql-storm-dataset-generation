WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = 1  -- Assuming region key 1 as top level
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= '2022-01-01')
),
PartSummary AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_cost > 1000.00
)
SELECT n.n_name, 
       COALESCE(SUM(co.o_totalprice), 0) AS total_order_value,
       SUM(ps.total_available) AS total_parts_available,
       ps.avg_supply_cost,
       ts.total_cost
FROM nation n
LEFT JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
LEFT JOIN CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN PartSummary ps ON 1=1  -- Join to get available parts in total
LEFT JOIN TopSuppliers ts ON ps.p_partkey IN (SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE n.n_regionkey IS NOT NULL
GROUP BY n.n_name, ps.avg_supply_cost, ts.total_cost
ORDER BY total_order_value DESC, n.n_name
LIMIT 10;
