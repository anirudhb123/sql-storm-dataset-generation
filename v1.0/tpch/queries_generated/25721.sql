WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, 
                  ', Available Qty: ', ps.ps_availqty, 
                  ', Supply Cost: ', FORMAT(ps.ps_supplycost, 2), 
                  ', Comment: ', ps.ps_comment) AS supplier_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderedCustomers AS (
    SELECT c.c_name, c.c_acctbal, o.o_orderkey, 
           CONCAT('Customer: ', c.c_name, ', Order Key: ', o.o_orderkey, 
                  ', Total Price: ', FORMAT(o.o_totalprice, 2), 
                  ', Account Balance: ', FORMAT(c.c_acctbal, 2)) AS customer_order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
)
SELECT sp.supplier_info, oc.customer_order_info
FROM SupplierParts sp
JOIN OrderedCustomers oc ON sp.ps_supplycost < oc.c_acctbal
ORDER BY sp.ps_supplycost ASC, oc.c_acctbal DESC
LIMIT 100;
