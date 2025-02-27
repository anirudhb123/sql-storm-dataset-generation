
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
), 
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
), 
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.o_orderkey, r.o_orderstatus, r.o_totalprice, r.o_orderdate, 
       c.c_name AS customer_name, 
       s.s_name AS supplier_name, 
       sd.avg_supply_cost,
       CASE 
           WHEN r.o_orderstatus = 'O' THEN 'Open'
           ELSE 'Closed'
       END AS order_status_desc
FROM RankedOrders r
LEFT JOIN HighValueCustomers c ON r.o_orderkey IN 
    (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN SupplierDetails s ON l.l_suppkey = s.s_suppkey
LEFT JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE r.rnk <= 10
ORDER BY r.o_totalprice DESC, r.o_orderdate ASC;
