WITH FilteredParts AS (
    SELECT p_partkey, 
           p_name, 
           p_brand, 
           p_type, 
           REPLACE(LOWER(p_comment), ' ', '') AS processed_comment 
    FROM part 
    WHERE LENGTH(p_comment) > 20
), SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank 
    FROM supplier s 
    WHERE s.s_acctbal > 5000 
), OrdersDetails AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           o.o_totalprice, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
) 
SELECT fp.p_name AS product_name, 
       fp.p_brand AS product_brand, 
       fp.processed_comment AS simplified_comment, 
       sd.s_name AS supplier_name, 
       od.total_sales AS order_total_sales 
FROM FilteredParts fp 
JOIN SupplierDetails sd ON EXISTS (
    SELECT 1 
    FROM partsupp ps 
    WHERE ps.ps_partkey = fp.p_partkey AND ps.ps_suppkey = sd.s_suppkey
) 
JOIN OrdersDetails od ON EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_partkey = fp.p_partkey AND l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F'
    )
) 
WHERE sd.rank <= 5 
ORDER BY fp.p_name, od.total_sales DESC;
