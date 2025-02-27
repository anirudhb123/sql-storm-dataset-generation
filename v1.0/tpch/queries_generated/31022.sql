WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
sales_data AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate > '2023-01-01' AND o.o_orderstatus IN ('O', 'P')
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00 AND ps.ps_availqty IS NOT NULL
),
summary AS (
    SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l
    JOIN part_supplier ps ON l.l_partkey = ps.p_partkey
    GROUP BY p.p_name
)
SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
       AVG(sd.o_totalprice) AS avg_order_price,
       COALESCE(SUM(supp.ps_supplycost), 0) AS total_supplycost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN sales_data sd ON sd.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
LEFT JOIN part_supplier supp ON n.n_nationkey = supp.ps_partkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1 AND TOTAL_SUPPLYCOST IS NOT NULL
ORDER BY avg_order_price DESC;
