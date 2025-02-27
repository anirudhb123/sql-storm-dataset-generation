WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) as rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.rnk <= 5
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(*) AS line_count, MIN(l.l_shipdate) AS first_ship_date, MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    JOIN TopOrders to ON l.l_orderkey = to.o_orderkey
    GROUP BY o.o_orderkey
)
SELECT to.orderkey, to.o_orderdate, to.o_totalprice, od.total_value, od.line_count, 
       od.first_ship_date, od.last_ship_date, 
       c.c_name, s.s_name, p.p_name
FROM TopOrders to
JOIN OrderDetails od ON to.o_orderkey = od.o_orderkey
JOIN customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = to.o_orderkey)
JOIN lineitem l ON l.l_orderkey = to.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE l.l_returnflag = 'N'
ORDER BY to.o_orderdate DESC, total_value DESC;
