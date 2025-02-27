WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rnk
    FROM customer
), EnhancedParts AS (
    SELECT p_partkey, p_name, p_brand, p_type,
           p_retailprice * 1.05 AS enhanced_price,
           CASE 
               WHEN p_size IS NULL THEN 'Unknown Size'
               ELSE p_size::text || ' units'
           END AS size_description
    FROM part
    WHERE p_retailprice IS NOT NULL
), SupplierAvailability AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_availqty) AS total_availqty,
           AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
), BestSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sa.total_availqty,
           RANK() OVER (ORDER BY sa.total_availqty DESC) AS supplier_rank
    FROM supplier s
    JOIN SupplierAvailability sa ON s.s_suppkey = sa.ps_suppkey
), OrdersSummary AS (
    SELECT o.o_orderkey, COUNT(li.l_orderkey) AS item_count,
           SUM(li.l_extendedprice) AS total_price
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY o.o_orderkey
)
SELECT c.c_name, e.enhanced_price, b.s_name AS best_supplier,
       COALESCE(o.item_count, 0) AS order_item_count,
       CASE 
           WHEN c.acctbal > 1000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_segment,
       CASE 
           WHEN e.enhanced_price IS NOT NULL AND e.enhanced_price > 200 THEN 'Premium Part'
           ELSE 'Standard Part'
       END AS part_category
FROM CustomerCTE c
LEFT JOIN EnhancedParts e ON e.p_partkey = (
    SELECT ps.ps_partkey
    FROM partsupp ps
    INNER JOIN BestSuppliers b ON ps.ps_suppkey = b.s_suppkey
    WHERE b.supplier_rank = 1
    LIMIT 1
)
LEFT JOIN BestSuppliers b ON b.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = e.p_partkey
    ORDER BY ps.ps_availqty DESC
    LIMIT 1
)
LEFT JOIN OrdersSummary o ON o.o_orderkey IN (
    SELECT o2.o_orderkey
    FROM orders o2
    WHERE o2.o_custkey = c.c_custkey AND o2.o_orderstatus = 'F'
)
WHERE c.rnk = 1
ORDER BY c.c_name ASC, e.enhanced_price DESC;
