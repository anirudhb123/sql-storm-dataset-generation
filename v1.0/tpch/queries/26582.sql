
WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Phone: ', s.s_phone) AS supplier_details
    FROM supplier s
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           CONCAT('Customer: ', c.c_name, ', Address: ', c.c_address, ', Phone: ', c.c_phone) AS customer_details
    FROM customer c
),
OrderInfo AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           CURRENT_DATE - o.o_orderdate AS days_since_order
    FROM orders o
),
LineItemInfo AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT si.s_name, ci.c_name, oi.days_since_order, li.total_price
FROM SupplierInfo si
JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN LineItemInfo li ON ps.ps_partkey = li.l_orderkey
JOIN OrderInfo oi ON li.l_orderkey = oi.o_orderkey
JOIN CustomerInfo ci ON oi.o_custkey = ci.c_custkey
WHERE oi.days_since_order BETWEEN 0 AND 30
  AND li.total_price > 100
ORDER BY li.total_price DESC, oi.days_since_order ASC;
