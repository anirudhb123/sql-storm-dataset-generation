WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Phone: ', s.s_phone) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE '%land%'
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, 
           CONCAT('Part: ', p.p_name, ', Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS part_info
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 30
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority, o.o_clerk,
           CONCAT('Order: ', o.o_orderkey, ', Status: ', o.o_orderstatus, ', Total Price: ', FORMAT(o.o_totalprice, 2)) AS order_info
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
)
SELECT sd.supplier_info, pd.part_info, od.order_info
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN lineitem li ON ps.ps_partkey = li.l_partkey
JOIN OrderDetails od ON li.l_orderkey = od.o_orderkey
WHERE sd.s_name NOT LIKE '%Test%'
ORDER BY od.o_orderdate, sd.supplier_info;
