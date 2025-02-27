WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_cost > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS row_num
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
),
AggregatedLineItems AS (
    SELECT od.o_orderkey, 
           SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_price
    FROM OrderDetails od
    GROUP BY od.o_orderkey
)
SELECT p.p_name, 
       r.r_name,
       SUM(ali.total_price) AS total_revenue,
       ts.s_name
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN AggregatedLineItems ali ON o.o_orderkey = ali.o_orderkey
JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE p.p_retailprice > 50
GROUP BY p.p_name, r.r_name, ts.s_name
HAVING SUM(ali.total_price) > 5000
ORDER BY total_revenue DESC
LIMIT 10;
