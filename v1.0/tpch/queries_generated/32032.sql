WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate)
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < oh.o_orderdate
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           COUNT(DISTINCT l.l_partkey) AS part_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > o.o_orderdate
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT oh.o_orderkey, 
       oh.o_orderdate, 
       oh.o_totalprice, 
       od.part_count, 
       od.total_line_value, 
       hs.total_supply_value,
       COALESCE(ROUND(od.total_line_value / NULLIF(oh.o_totalprice, 0), 2), 0) AS price_ratio,
       RANK() OVER (ORDER BY od.total_line_value DESC) AS total_value_rank
FROM OrderHierarchy oh
LEFT JOIN OrderDetails od ON oh.o_orderkey = od.o_orderkey
LEFT JOIN HighValueSuppliers hs ON hs.s_suppkey = (SELECT ps.ps_suppkey 
                                                    FROM partsupp ps
                                                    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                                    WHERE l.l_orderkey = oh.o_orderkey 
                                                    LIMIT 1)
WHERE od.part_count > 5
ORDER BY price_ratio DESC, total_value_rank;
