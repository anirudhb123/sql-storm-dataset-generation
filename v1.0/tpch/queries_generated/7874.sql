WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost) > 1000
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(co.total_revenue) AS total_revenue,
       AVG(tp.total_cost) AS avg_part_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN CustomerOrderDetails co ON co.c_custkey = (SELECT c.c_custkey
                                                 FROM customer c
                                                 WHERE c.c_nationkey = n.n_nationkey
                                                 LIMIT 1)
JOIN RankedParts tp ON tp.p_partkey = (SELECT ps.ps_partkey
                                          FROM partsupp ps
                                          WHERE ps.ps_suppkey = ts.s_suppkey
                                          LIMIT 1)
GROUP BY r.r_name
ORDER BY total_orders DESC, total_revenue DESC;
