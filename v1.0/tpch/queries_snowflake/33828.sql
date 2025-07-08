
WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'

    UNION ALL

    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND co.level < 5
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
OrderLineStatus AS (
    SELECT l.l_orderkey, l.l_linestatus, COUNT(*) AS status_count
    FROM lineitem l
    WHERE l.l_shipdate < DATEADD(DAY, -100, '1998-10-01'::DATE)
    GROUP BY l.l_orderkey, l.l_linestatus
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT co.c_custkey, co.c_name, co.o_orderkey, 
       co.o_orderdate, co.o_totalprice, 
       spd.p_partkey, spd.p_name, 
       ols.l_linestatus, ols.status_count,
       rs.s_name AS supplier_name, rs.rank
FROM CustomerOrders co
LEFT JOIN lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN OrderLineStatus ols ON l.l_orderkey = ols.l_orderkey
LEFT JOIN SupplierPartDetails spd ON spd.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
WHERE co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
  AND ols.l_linestatus IS NOT NULL
ORDER BY co.o_orderdate DESC, co.o_totalprice DESC
LIMIT 100;
