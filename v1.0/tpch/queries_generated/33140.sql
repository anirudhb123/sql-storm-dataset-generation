WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')

    UNION ALL

    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM CustomerOrders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM SupplierParts ps
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supplycost DESC
    LIMIT 10
)

SELECT p.p_name, p.p_retailprice, COALESCE(MAX(o.o_totalprice), 0) AS max_order_total,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       AVG(NULLIF(o.o_totalprice, 0)) OVER (PARTITION BY p.p_partkey) AS avg_order_price,
       SUM(CASE WHEN ps.ps_availqty < 10 THEN ps.ps_availqty ELSE 0 END) AS low_stock_units
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierParts ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
AND (o.o_orderdate < CURRENT_DATE OR o.o_orderdate IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING order_count > 5
ORDER BY max_order_total DESC, p.p_name;
