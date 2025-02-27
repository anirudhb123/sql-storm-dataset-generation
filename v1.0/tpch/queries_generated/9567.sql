WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
TopOrders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, c.c_name, n.n_name AS nation_name
    FROM RankedOrders r
    JOIN customer c ON r.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE r.order_rank <= 5
),
SuppliersWithCosts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_acctbal, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY ps.ps_partkey, ps.ps_suppkey, s.s_acctbal
)
SELECT t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name, t.nation_name, 
       s.s_suppkey, s.total_cost, s.s_acctbal
FROM TopOrders t
JOIN SuppliersWithCosts s ON s.ps_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = t.o_orderkey
)
ORDER BY t.o_orderdate DESC, t.o_totalprice DESC;
