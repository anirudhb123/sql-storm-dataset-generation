WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
SalesByCustomer AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
    COALESCE(hv.total_supply_value, 0) AS supplier_value,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN HighValueSuppliers hv ON l.l_suppkey = hv.s_suppkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.c_custkey, c.c_name, hv.total_supply_value
HAVING total_order_value > 5000
ORDER BY total_order_value DESC, customer_name
LIMIT 10;
