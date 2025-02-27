
WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    INNER JOIN CustomerOrders co ON co.o_orderkey = o.o_orderkey
),
HighValueOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 500
    GROUP BY c.c_custkey, c.c_name
),
SupplierRatings AS (
    SELECT ps.ps_partkey, s.s_suppkey, AVG(s.s_acctbal) AS avg_supplier_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
)
SELECT DISTINCT
    c.c_name AS customer_name,
    o.o_orderdate AS order_date,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_order_value,
    COUNT(DISTINCT l.l_orderkey) AS number_of_orders,
    AVG(sr.avg_supplier_balance) AS average_supplier_balance
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierRatings sr ON sr.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#12')
WHERE o.o_orderstatus = 'F'
AND l.l_returnflag = 'N'
GROUP BY c.c_name, o.o_orderdate
HAVING COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 1000
ORDER BY total_order_value DESC
LIMIT 50;
