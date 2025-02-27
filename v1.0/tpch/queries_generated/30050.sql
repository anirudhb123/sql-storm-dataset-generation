WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, cte.level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_avail_qty, AVG(l.l_discount) AS avg_discount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier s
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_avail_qty,
    ps.avg_discount,
    co.order_count,
    co.total_spent,
    rs.s_name AS top_supplier,
    rs.rank
FROM PartStats ps
JOIN CustomerOrders co ON co.order_count > 0
LEFT JOIN RankedSuppliers rs ON ps.p_partkey = rs.s_suppkey
WHERE ps.avg_discount IS NOT NULL
AND (rs.rank IS NULL OR rs.rank <= 3)
ORDER BY ps.total_avail_qty DESC, co.total_spent DESC;
