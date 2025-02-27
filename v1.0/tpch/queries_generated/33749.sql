WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(NULL AS VARCHAR(255)) AS manager_name,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           sh.s_name AS manager_name,
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_acctbal < sh.s_acctbal AND sh.level < 5
),
part_details AS (
    SELECT p.p_partkey, p.p_name, 
           p.p_retailprice, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, 
           SUM(CASE WHEN c.c_mktsegment = 'AUTOMOBILE' THEN o.o_totalprice ELSE 0 END) AS total_automobile_sales
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
ordered_part AS (
    SELECT part.p_partkey, part.p_name,
           ROW_NUMBER() OVER (ORDER BY part.p_retailprice DESC) AS price_rank
    FROM part part
    WHERE part.p_size BETWEEN 5 AND 20
)
SELECT ns.n_name, 
       SUM(ns.total_automobile_sales) AS total_sales, 
       ROUND(AVG(pd.p_retailprice), 2) AS average_retail_price,
       MAX(op.price_rank) AS highest_price_rank,
       COUNT(DISTINCT sh.s_suppkey) AS active_suppliers
FROM nation_summary ns
JOIN part_details pd ON ns.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_acctbal > 100000)
JOIN ordered_part op ON pd.p_partkey = op.p_partkey
LEFT JOIN supplier_hierarchy sh ON sh.manager_name IS NULL
WHERE ns.total_automobile_sales > 100000
GROUP BY ns.n_name
HAVING COUNT(DISTINCT op.p_partkey) > 10
ORDER BY total_sales DESC, average_retail_price DESC;
