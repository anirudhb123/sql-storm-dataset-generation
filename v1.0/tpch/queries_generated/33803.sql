WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > oh.o_orderdate
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING SUM(ps.ps_availqty) > 0
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING AVG(o.o_totalprice) > 100
),
LineItemStats AS (
    SELECT l.l_orderkey, COUNT(*) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
HighValueCustomers AS (
    SELECT cs.c_custkey, cs.c_name
    FROM CustomerSummary cs
    JOIN FilteredParts fp ON cs.avg_order_value > (SELECT AVG(avg_order_value) FROM CustomerSummary)
),
TopSuppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_supply_cost) FROM (
        SELECT SUM(ps_supplycost * ps_availqty) AS total_supply_cost
        FROM supplier s_a
        JOIN partsupp ps_a ON s_a.s_suppkey = ps_a.ps_suppkey
        GROUP BY s_a.s_suppkey) AS avg_suppliers
    )
)
SELECT oh.o_orderkey,
       oh.o_orderdate,
       oh.o_totalprice,
       cs.c_name AS customer_name,
       cs.avg_order_value,
       li.line_count,
       li.total_revenue,
       ts.total_supply_cost
FROM OrderHierarchy oh
JOIN HighValueCustomers cs ON oh.o_custkey = cs.c_custkey
JOIN LineItemStats li ON oh.o_orderkey = li.l_orderkey
JOIN TopSuppliers ts ON ts.total_supply_cost > 1000
ORDER BY oh.o_orderdate DESC, total_revenue DESC;
