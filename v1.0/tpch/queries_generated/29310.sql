WITH FilteredParts AS (
    SELECT p_partkey, 
           p_name, 
           LENGTH(p_name) AS name_length, 
           SUBSTRING(p_name FROM 1 FOR 10) AS short_name,
           p_mfgr
    FROM part
    WHERE p_size >= 12
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey,
           CONCAT('Supplier: ', s.s_name, ', Location: ', s.s_address) AS full_supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE '%UNITED%'
),
CustomerOrders AS (
    SELECT o.o_orderkey, 
           c.c_name, 
           COUNT(l.l_orderkey) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, c.c_name
)
SELECT fp.p_partkey, 
       fp.p_name, 
       fd.full_supplier_info, 
       co.c_name, 
       co.total_lines, 
       co.total_price
FROM FilteredParts fp
JOIN SupplierDetails fd ON fp.p_mfgr LIKE '%' || fd.s_suppkey || '%'
JOIN CustomerOrders co ON co.total_lines > 5
WHERE fp.name_length > 10
ORDER BY co.total_price DESC, fp.p_name;
