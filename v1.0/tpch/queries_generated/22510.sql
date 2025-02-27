WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, 1 AS level
    FROM part
    WHERE p_brand LIKE 'Brand%'
    
    UNION ALL
    
    SELECT p.partkey, CONCAT(r.p_name, ' -> ', p.p_name), r.p_brand, r.p_retailprice + p.p_retailprice, level + 1
    FROM part p
    JOIN RecursivePart r ON p.p_partkey = r.p_partkey
    WHERE r.level < 5
), 
TotalSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
), 
HighestSales AS (
    SELECT c.c_custkey, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM TotalSales c
), 
SuppSales AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)

SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    hs.total_sales,
    COALESCE(ss.total_supplycost, 0) AS total_supplycost,
    CASE 
        WHEN hs.total_sales IS NULL THEN 'No Sales'
        WHEN hs.total_sales > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY rp.p_brand ORDER BY rp.p_retailprice DESC) AS price_rank
FROM RecursivePart rp
LEFT JOIN HighestSales hs ON hs.c_custkey = (SELECT c_custkey FROM customer ORDER BY c_acctbal DESC LIMIT 1)
LEFT JOIN SuppSales ss ON ss.s_suppkey = (SELECT s_suppkey FROM supplier ORDER BY s_acctbal DESC LIMIT 1)
WHERE rp.p_retailprice > 0
AND (rp.p_brand LIKE 'Brand%' OR rp.p_name IS NOT NULL)
AND EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.o_orderkey IN (
        SELECT o2.o_orderkey
        FROM lineitem l2
        JOIN orders o2 ON l2.l_orderkey = o2.o_orderkey
        WHERE l2.l_returnflag = 'R'
    )
)
ORDER BY rp.p_brand, total_sales DESC, price_rank;
