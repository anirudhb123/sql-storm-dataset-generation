WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, h.level + 1
    FROM orders oh
    JOIN OrderHierarchy h ON oh.o_orderkey = h.o_orderkey
    WHERE h.level < 5
),
SupplierProfit AS (
    SELECT ps.ps_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name,
           COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
           pd.total_profit,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY pd.total_profit DESC) as rank
    FROM part p
    LEFT JOIN supplier s ON p.p_partkey = s.s_suppkey
    LEFT JOIN SupplierProfit pd ON p.p_partkey = pd.ps_partkey
)
SELECT r.r_name AS region_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       MAX(pd.total_profit) AS max_profit,
       STRING_AGG(DISTINCT pd.p_name, ', ') AS popular_parts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN OrderHierarchy oh ON oh.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
  AND r.r_comment NOT LIKE '%sample%'
GROUP BY r.r_name
ORDER BY max_profit DESC
LIMIT 10;
