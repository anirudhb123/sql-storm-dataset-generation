WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineDetail AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2021-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    ss.s_name,
    cs.c_name,
    cs.total_orders,
    cs.order_count,
    ss.total_parts,
    ss.total_supplycost,
    o.total_lineitem_sales
FROM SupplierSummary ss
JOIN CustomerSummary cs ON ss.total_parts > 5
JOIN OrderLineDetail o ON cs.order_count > 10
WHERE ss.total_supplycost > 10000
ORDER BY ss.total_supplycost DESC, cs.total_orders DESC
LIMIT 50;
