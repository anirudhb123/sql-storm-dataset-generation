WITH SupplyCostRanked AS (
    SELECT ps_partkey, ps_suppkey, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank, 
           (ps_availqty * ps_supplycost) AS total_cost
    FROM partsupp
), FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           COALESCE(NULLIF(s.s_comment, ''), 'No comments available') AS comment
    FROM supplier s 
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
), OrderStats AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           COUNT(DISTINCT o.o_orderkey) OVER (PARTITION BY o.o_orderstatus) AS total_orders_by_status,
           SUM(o.o_totalprice) OVER () AS grand_total_sales
    FROM orders o
)

SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand,
       SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
       AVG(s.total_cost) AS avg_supply_cost,
       ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY revenue DESC) AS brand_rank,
       CASE 
           WHEN p.p_size IS NULL THEN 'Unknown size'
           WHEN p.p_size < 10 THEN 'Small'
           WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
           ELSE 'Large'
       END AS size_category,
       STRING_AGG(DISTINCT f.s_name, ', ') AS suppliers
FROM part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN SupplyCostRanked scr ON p.p_partkey = scr.ps_partkey AND scr.rank = 1
LEFT JOIN FilteredSuppliers f ON scr.ps_suppkey = f.s_suppkey
WHERE EXISTS (
    SELECT 1 FROM nation n 
    WHERE n.n_nationkey = f.s_nationkey 
    AND n.n_name LIKE 'C%'
)
AND li.l_shipdate <= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_size
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY revenue DESC, p.p_name ASC
LIMIT 50;
