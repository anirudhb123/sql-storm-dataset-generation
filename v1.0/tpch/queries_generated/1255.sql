WITH Supplier_Costs AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
Customer_Orders AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey
),
Qualified_Suppliers AS (
    SELECT s.s_suppkey, s.s_name,
           COALESCE(sc.total_supply_cost, 0) AS supplier_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COALESCE(sc.total_supply_cost, 0) DESC) AS rank
    FROM supplier s
    LEFT JOIN Supplier_Costs sc ON s.s_suppkey = sc.s_suppkey
)
SELECT DISTINCT
    n.n_name AS nation_name,
    q.s_name AS supplier_name,
    q.supplier_cost,
    c.order_count,
    c.total_spent
FROM nation n
LEFT JOIN Qualified_Suppliers q ON n.n_nationkey = q.s_nationkey AND q.rank <= 3
LEFT JOIN Customer_Orders c ON c.c_custkey IN (
    SELECT c2.c_custkey
    FROM customer c2
    WHERE c2.c_nationkey = n.n_nationkey
)
WHERE q.supplier_cost IS NOT NULL
ORDER BY n.n_name, q.supplier_cost DESC;
