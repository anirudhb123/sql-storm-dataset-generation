WITH SupplierCost AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_orderkey) AS total_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           r.r_name AS region_name,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(sc.total_supply_cost) DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
)
SELECT DISTINCT
       p.p_name,
       COUNT(DISTINCT od.o_orderkey) AS order_count,
       SUM(od.total_price) AS total_order_value,
       ts.region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierCost sc ON ps.ps_partkey = sc.ps_partkey
LEFT JOIN TopSuppliers ts ON sc.ps_suppkey = ts.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey
                                               FROM lineitem l
                                               JOIN orders o ON l.l_orderkey = o.o_orderkey
                                               WHERE l.l_partkey = p.p_partkey
                                               ORDER BY o.o_orderdate DESC
                                               LIMIT 1)
WHERE p.p_retailprice > 100.00
  AND (ts.supplier_rank IS NULL OR ts.supplier_rank <= 3)
GROUP BY p.p_name, ts.region_name
ORDER BY total_order_value DESC
LIMIT 10;
