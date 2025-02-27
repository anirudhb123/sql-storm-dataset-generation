WITH FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, 
           REPLACE(LOWER(p.p_comment), 'urgent', 'important') AS modified_comment
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
      AND p.p_brand LIKE 'A%'
), SupplierStats AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS total_parts, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           STRING_AGG(DISTINCT p.p_brand, ', ') AS unique_brands
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN FilteredParts p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank,
           CONCAT('Order Date: ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD')) AS order_info
    FROM orders o
    WHERE o.o_orderstatus = 'O'
), CombinedResults AS (
    SELECT ss.total_parts, ss.total_avail_qty, ss.unique_brands, 
           od.o_orderkey, od.o_totalprice, od.price_rank, od.order_info
    FROM SupplierStats ss
    JOIN OrderDetails od ON ss.total_parts > 0
    ORDER BY ss.total_parts DESC, od.o_totalprice ASC
)
SELECT total_parts, total_avail_qty, unique_brands, o_orderkey, 
       o_totalprice, price_rank, order_info
FROM CombinedResults
WHERE price_rank <= 10;
