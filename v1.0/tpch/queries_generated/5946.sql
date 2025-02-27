WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) as rank
    FROM customer c
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_supply_value > (SELECT AVG(total_supply_value)
                                  FROM (SELECT SUM(ps_supplycost * ps_availqty) AS total_supply_value
                                        FROM partsupp ps
                                        GROUP BY ps.ps_suppkey) AS avg_supply)
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
           COUNT(l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT r.r_name AS region_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(ts.total_supply_value) AS total_supplier_value,
       AVG(os.order_value) AS average_order_value,
       AVG(os.line_item_count) AS average_lines_per_order
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN RankedCustomers rc ON n.n_nationkey = rc.c_nationkey
JOIN TopSuppliers ts ON ts.total_supply_value > 0
JOIN OrderStatistics os ON os.o_orderkey = (SELECT o_orderkey FROM orders ORDER BY o_orderdate LIMIT 1 OFFSET RANDOM())
WHERE rc.rank <= 10
GROUP BY r.r_name
ORDER BY customer_count DESC, total_supplier_value DESC;
