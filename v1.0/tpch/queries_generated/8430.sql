WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderpriority,
           c.c_name AS customer_name,
           s.s_name AS supplier_name,
           p.p_name AS part_name,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
CategorySummary AS (
    SELECT p.p_type AS part_type,
           SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_discounted_sales,
           COUNT(DISTINCT o.o_orderkey) AS number_of_orders
    FROM RankedOrders ro
    JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY p.p_type
)
SELECT cs.part_type,
       cs.total_discounted_sales,
       cs.number_of_orders,
       (SELECT COUNT(*) FROM supplier) AS total_suppliers,
       (SELECT COUNT(*) FROM customer) AS total_customers
FROM CategorySummary cs
ORDER BY cs.total_discounted_sales DESC
LIMIT 10;
