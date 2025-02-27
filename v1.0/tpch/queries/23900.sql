WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING AVG(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT DISTINCT r.r_name, 
       COALESCE(HS.total_supply_cost, 0) AS total_supply_cost,
       HVO.avg_order_value
FROM region r
LEFT JOIN RankedSuppliers HS ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n 
                                                  WHERE n.n_nationkey = HS.s_suppkey)
LEFT JOIN HighValueOrders HVO ON HVO.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderkey % 2 = 0 AND o.o_orderstatus = 'O'
)
WHERE HVO.avg_order_value IS NULL 
   OR HS.total_supply_cost IS NOT NULL
ORDER BY r.r_name ASC, total_supply_cost DESC NULLS LAST;
