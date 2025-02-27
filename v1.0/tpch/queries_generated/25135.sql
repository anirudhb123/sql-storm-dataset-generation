WITH SupplierProducts AS (
    SELECT s.s_name AS supplier_name, p.p_name AS product_name, p.p_brand, p.p_type, p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
ProductBrands AS (
    SELECT p_brand, COUNT(*) AS brand_count
    FROM SupplierProducts
    GROUP BY p_brand
    HAVING COUNT(*) > 5
), 
CustomerOrders AS (
    SELECT o.o_orderkey, c.c_name AS customer_name, SUM(l.l_extendedprice) AS total_order_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
    HAVING SUM(l.l_extendedprice) > 1000
)
SELECT p.p_brand, pb.brand_count, co.customer_name, co.total_order_value
FROM ProductBrands pb
JOIN SupplierProducts p ON p.p_brand = pb.p_brand
JOIN CustomerOrders co ON p.product_name LIKE '%' || co.customer_name || '%'
ORDER BY pb.brand_count DESC, co.total_order_value DESC
LIMIT 10;
