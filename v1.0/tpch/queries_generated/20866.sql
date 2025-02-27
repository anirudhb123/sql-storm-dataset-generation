WITH RECURSIVE Supplier_CTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sc.level + 1
    FROM supplier s
    JOIN Supplier_CTE sc ON sc.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sc.s_acctbal
),
High_Value_Customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
Part_Supplier_Info AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
Lineitem_Analysis AS (
    SELECT l.l_orderkey, COUNT(*) AS num_items, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
Filtered_Orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, la.num_items, la.total_value
    FROM orders o
    JOIN Lineitem_Analysis la ON o.o_orderkey = la.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') AND la.total_value > 5000
),
Nationary_Supply_Orders AS (
    SELECT n.n_name, SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN Filtered_Orders o ON ps.ps_partkey = o.o_orderkey
    GROUP BY n.n_name
)
SELECT nsi.n_name, nsi.open_orders, nsi.fulfilled_orders, COALESCE(sc.s_name, 'No Supplier') as supplier_name
FROM Nationary_Supply_Orders nsi
LEFT JOIN Supplier_CTE sc ON nsi.open_orders > 0
WHERE nsi.open_orders > nsi.fulfilled_orders
ORDER BY nsi.n_name ASC, nsi.fulfilled_orders DESC
LIMIT 10;
