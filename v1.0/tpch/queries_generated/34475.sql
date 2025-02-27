WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
      AND o.o_orderdate >= DATE '2023-01-01'
),
supplier_parts AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
high_priority_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderpriority = 'High'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT c.c_name, co.o_orderkey, co.o_totalprice, co.o_orderdate,
       sp.total_available, sp.avg_supply_cost,
       ho.line_item_count
FROM customer_orders co
JOIN customer c ON c.c_custkey = co.c_custkey
LEFT JOIN supplier_parts sp ON sp.s_suppkey = (SELECT ps.ps_suppkey
                                               FROM partsupp ps
                                               JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                               WHERE l.l_orderkey = co.o_orderkey
                                               LIMIT 1)
LEFT JOIN high_priority_orders ho ON co.o_orderkey = ho.o_orderkey
WHERE co.order_rank = 1 OR ho.line_item_count > 5
ORDER BY co.o_orderdate DESC, c.c_name;
