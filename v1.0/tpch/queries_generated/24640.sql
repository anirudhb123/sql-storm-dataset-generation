WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
),
DistinctParts AS (
    SELECT DISTINCT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey AND l.l_shipdate >= '2022-01-01'
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
SalesRanked AS (
    SELECT dp.*, 
           ROW_NUMBER() OVER (PARTITION BY dp.p_partkey ORDER BY dp.total_sales DESC) AS sales_rank,
           RANK() OVER (ORDER BY dp.total_sales DESC) AS total_sales_rank,
           DENSE_RANK() OVER (ORDER BY p_retailprice ASC) AS price_rank
    FROM DistinctParts dp
    WHERE dp.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
ExceptionalOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           CASE 
               WHEN o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
                    THEN 'High Value' 
               ELSE 'Standard' 
           END AS order_value,
           COALESCE(SUM(li.l_quantity), 0) AS total_quantity,
           AVG(li.l_discount) AS avg_discount
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT sh.s_name AS supplier_name, 
       COUNT(DISTINCT eo.o_orderkey) AS order_count,
       SUM(eo.total_quantity) AS total_line_items,
       COUNT(DISTINCT sr.p_partkey) AS distinct_parts_supplied,
       MAX(sr.total_sales) AS max_part_sales,
       MIN(sr.total_sales) AS min_part_sales,
       AVG(eo.avg_discount) AS avg_discount,
       (CASE WHEN COUNT(DISTINCT eo.o_orderkey) > 100 THEN 'VIP Supplier' ELSE 'Regular Supplier' END) AS supplier_status
FROM SupplierHierarchy sh
JOIN ExceptionalOrders eo ON sh.s_suppkey = eo.o_orderkey
JOIN SalesRanked sr ON eo.o_totalprice = sr.total_sales
WHERE sr.sales_rank = 1 AND eo.order_value = 'High Value'
GROUP BY sh.s_name
HAVING COUNT(DISTINCT eo.o_orderkey) > 5 AND AVG(sr.price_rank) < 10
ORDER BY total_line_items DESC, supplier_name ASC;
