WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE oh.level < 5
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
LineitemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           CASE
               WHEN l.l_discount > 0.1 THEN 'High Discount'
               ELSE 'Regular Discount'
           END AS discount_category
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    c.c_name AS customer_name,
    oh.o_orderkey,
    oh.o_orderdate,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_order_value,
    PERCENT_RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank,
    sp.total_cost AS part_total_cost,
    rd.r_name AS region_name
FROM CustomerSpending c
JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplierparts sp ON ps.ps_partkey = sp.ps_partkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region rd ON n.n_regionkey = rd.r_regionkey
WHERE c.c_name IS NOT NULL
    AND (sp.total_cost IS NULL OR sp.total_cost > 5000)
GROUP BY c.c_custkey, customer_name, oh.o_orderkey, oh.o_orderdate, rd.r_name
HAVING COUNT(l.l_orderkey) > 1
ORDER BY total_order_value DESC;
