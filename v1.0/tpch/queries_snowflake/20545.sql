
WITH RECURSIVE OrderHistory AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O')
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           MAX(s.s_acctbal) AS max_acctbal,
           NTILE(5) OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerPreferences AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_price,
           CASE 
               WHEN COUNT(o.o_orderkey) = 0 THEN 'NO ORDERS'
               WHEN AVG(o.o_totalprice) > 500 THEN 'HIGH SPENDER'
               ELSE 'AVERAGE SPENDER'
           END AS customer_type
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT ch.c_name AS customer_name, ch.customer_type, os.o_orderkey, os.o_totalprice,
       rs.s_name AS supplier_name, rs.total_supply_cost,
       LEAD(os.o_orderdate) OVER (PARTITION BY ch.c_custkey ORDER BY os.o_orderdate) AS next_order_date,
       CASE
           WHEN ch.customer_type = 'HIGH SPENDER' AND rs.supplier_rank = 1 THEN 'PREFERRED SUPPLIER'
           ELSE 'REGULAR SUPPLIER'
       END AS supplier_status
FROM CustomerPreferences ch
JOIN OrderHistory os ON ch.c_custkey = os.o_custkey
LEFT JOIN RankedSuppliers rs ON os.o_orderkey = rs.s_suppkey
WHERE os.o_orderdate = (SELECT MAX(o.o_orderdate)
                          FROM orders o
                          WHERE o.o_custkey = os.o_custkey)
   OR (rs.total_supply_cost IS NULL AND ch.customer_type = 'NO ORDERS')
ORDER BY ch.c_name, os.o_orderdate DESC;
