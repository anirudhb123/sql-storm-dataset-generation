WITH RECURSIVE FilteredParts AS (
    SELECT p_partkey, p_name, p_retailprice
    FROM part
    WHERE p_size >= (
        SELECT AVG(p_size) 
        FROM part
        WHERE p_comment IS NOT NULL
    )
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    JOIN FilteredParts fp ON p.p_partkey < fp.p_partkey
    WHERE p.p_retailprice > (0.9 * fp.p_retailprice)
), Ranks AS (
    SELECT p_partkey, 
           ROW_NUMBER() OVER (PARTITION BY p_partkey ORDER BY p_name) AS rank,
           COUNT(*) OVER () as total_parts
    FROM FilteredParts
    WHERE p_name NOT LIKE '%dummy%'
), SuppliersWithOrders AS (
    SELECT s.s_suppkey,
           SUM(o.o_totalprice) AS total_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
), CustomerSegmentation AS (
    SELECT c.c_custkey,
           CASE 
               WHEN c.c_acctbal < 0 AND c_mktsegment = 'AUTOMOBILE' THEN 'Negative Automobile'
               WHEN c.c_acctbal > 0 AND c_mktsegment = 'FURNITURE' THEN 'Positive Furniture'
               ELSE 'Regular'
           END AS segment
    FROM customer c
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(sp.total_value, 0) AS supplier_total_value,
    c.segment AS customer_segment,
    (SELECT COUNT(*) 
     FROM lineitem l2 
     WHERE l2.l_partkey = p.p_partkey AND l2.l_returnflag = 'R') AS return_count,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS retail_rank
FROM part p
LEFT JOIN SuppliersWithOrders sp ON p.p_partkey = sp.s_suppkey
JOIN CustomerSegmentation c ON c.c_custkey = (
    SELECT o.o_custkey
    FROM orders o 
    WHERE o.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
        LIMIT 1
    )
)
WHERE EXISTS (
    SELECT 1 
    FROM FilteredParts fp 
    WHERE fp.p_partkey = p.p_partkey
)
ORDER BY retail_rank, supplier_total_value DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM region WHERE r_name IS NOT NULL) % 10;
