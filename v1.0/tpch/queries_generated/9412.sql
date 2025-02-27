WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderstatus = 'O' 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.nation_name
    FROM RankedOrders ro
    WHERE ro.order_rank <= 5
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    to.nation_name
FROM TopOrders to
JOIN lineitem l ON to.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
GROUP BY p.p_name, to.nation_name
ORDER BY revenue DESC
LIMIT 10;
