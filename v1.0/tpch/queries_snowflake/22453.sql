
WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn,
           p.p_retailprice,
           COALESCE(NULLIF(p.p_comment, ''), 'NO_COMMENT') AS sanitized_comment
    FROM part p
), SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N' 
    GROUP BY s.s_suppkey
), CustomerOrders AS (
    SELECT o.o_custkey, COUNT(*) AS order_count, 
           SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal > 100
    GROUP BY o.o_custkey
), FilteredRegions AS (
    SELECT r.r_regionkey, 
           ROW_NUMBER() OVER (ORDER BY r.r_name) AS region_rank
    FROM region r
    WHERE LENGTH(r.r_comment) > 10 AND r.r_name IS NOT NULL
), OuterJoinExample AS (
    SELECT p.p_partkey, p.p_name, s.total_sales
    FROM RankedParts p
    LEFT JOIN SupplierSales s ON p.p_partkey = s.s_suppkey
    WHERE p.rn = 1
)
SELECT r.r_regionkey, r.region_rank, 
       o.order_count, 
       COALESCE(o.total_order_value, 0) AS total_order_value,
       CASE 
           WHEN r.region_rank % 2 = 0 THEN 'Even'
           ELSE 'Odd'
       END AS rank_type,
       COUNT(DISTINCT p.p_partkey) AS part_count
FROM FilteredRegions r
LEFT JOIN CustomerOrders o ON r.r_regionkey = (SELECT n.n_regionkey 
                                                FROM nation n 
                                                WHERE n.n_nationkey = o.o_custkey % (SELECT COUNT(*) FROM nation))
LEFT JOIN OuterJoinExample p ON p.p_partkey IN (SELECT p_partkey FROM part WHERE p_brand LIKE 'Brand%')
GROUP BY r.r_regionkey, r.region_rank, o.order_count, o.total_order_value
HAVING COUNT(p.p_partkey) > 1 AND (o.total_order_value < 10000 OR o.total_order_value IS NULL)
ORDER BY r.region_rank DESC, total_order_value ASC;
