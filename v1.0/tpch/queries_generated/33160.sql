WITH RECURSIVE region_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           r.r_name AS region_name,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > 10.00
),
top_suppliers AS (
    SELECT * FROM region_suppliers
    WHERE rank <= 3
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2021-01-01'
    GROUP BY o.o_orderkey
)
SELECT r.region_name,
       COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
       AVG(od.total_price) AS avg_order_price,
       SUM(CASE WHEN od.supplier_count > 1 THEN 1 ELSE 0 END) AS multi_supplier_orders
FROM top_suppliers ts
LEFT JOIN order_details od ON ts.s_nationkey = od.o_orderkey
LEFT JOIN nation n ON ts.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.region_name
ORDER BY supplier_count DESC, avg_order_price DESC
LIMIT 5;
