WITH RECURSIVE Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM Customer_Orders co
    JOIN orders o ON co.c_custkey = o.o_custkey AND o.o_orderdate > co.o_orderdate
),
Filtered_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    GROUP BY s.s_suppkey, s.s_name
),
Part_Statistics AS (
    SELECT p.p_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N'
    GROUP BY p.p_partkey
),
Sales_Ranking AS (
    SELECT *,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM Part_Statistics
)
SELECT co.c_name, 
       f.s_name,
       ps.p_partkey AS top_partkey,
       ps.total_sales,
       ps.order_count,
       RANK() OVER (PARTITION BY co.c_custkey ORDER BY CASE WHEN ps.total_sales IS NULL THEN 0 ELSE ps.total_sales END DESC) AS customer_rank
FROM Customer_Orders co
JOIN Filtered_Suppliers f ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = f.s_suppkey)
LEFT JOIN Sales_Ranking ps ON co.o_orderkey = ps.p_partkey
WHERE f.part_count > 1 OR f.s_name LIKE '%Corp%'
ORDER BY co.c_name, f.s_name, customer_rank
LIMIT 50 OFFSET (SELECT COUNT(*) FROM customer) * RANDOM();
