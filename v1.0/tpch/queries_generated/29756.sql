WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS full_info
    FROM supplier s
), 
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand) AS full_info
    FROM part p
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           CONCAT('Order ID: ', o.o_orderkey, ', Total Price: ', o.o_totalprice) AS full_info
    FROM orders o
), 
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CONCAT('Customer: ', c.c_name, ', Balance: ', c.c_acctbal) AS full_info
    FROM customer c
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, 
           CONCAT('Line Item: Order ', l.l_orderkey, ', Part ', l.l_partkey) AS full_info
    FROM lineitem l
)
SELECT 
    ra.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    STRING_AGG(DISTINCT sd.full_info, '; ') AS supplier_info,
    STRING_AGG(DISTINCT p.full_info, '; ') AS part_info,
    STRING_AGG(DISTINCT od.full_info, '; ') AS order_info
FROM region ra
JOIN nation n ON ra.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
GROUP BY ra.r_name
ORDER BY total_revenue DESC;
