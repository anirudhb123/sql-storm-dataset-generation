WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_retailprice, p_size, 
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS price_rank
    FROM part
    WHERE p_size > 0
),
SupplierCount AS (
    SELECT ps_partkey, COUNT(DISTINCT ps_suppkey) AS supplier_count
    FROM partsupp
    GROUP BY ps_partkey
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, 
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT ss.p_partkey, ss.p_name, ss.p_retailprice, ss.price_rank, 
       sc.supplier_count, 
       co.c_custkey, co.c_name, co.order_rank,
       COALESCE(REGEXP_REPLACE(ss.p_comment, '\s+', ' ', 'g'), 'No Comment') AS cleaned_comment,
       CASE 
           WHEN sc.supplier_count IS NULL THEN 'No Suppliers'
           WHEN sc.supplier_count > 10 THEN 'Many Suppliers'
           ELSE 'Few Suppliers' 
       END AS supplier_count_description
FROM RecursivePart ss
LEFT JOIN SupplierCount sc ON ss.p_partkey = sc.ps_partkey
RIGHT JOIN CustomerOrder co ON co.o_orderkey IN (
    SELECT o_orderkey FROM orders WHERE o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    HAVING COUNT(o_orderkey) > 5
)
WHERE ss.price_rank <= 3 AND
      (ss.p_retailprice + COALESCE(sc.supplier_count, 0) * 2 > 50 OR 
      EXISTS (SELECT 1 FROM lineitem li WHERE li.l_partkey = ss.p_partkey AND li.l_quantity > 100))
ORDER BY ss.price_rank, co.order_rank DESC
FETCH FIRST 50 ROWS ONLY;
