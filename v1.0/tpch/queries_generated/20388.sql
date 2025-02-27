WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_name LIKE 'N%'
    
    UNION ALL
    
    SELECT r.regionkey, r.r_name, rh.level + 1
    FROM region_hierarchy rh
    JOIN nation n ON rh.r_regionkey = n.n_regionkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name IS NOT NULL
),
supplier_summary AS (
    SELECT s_nationkey, 
           COUNT(DISTINCT s_suppkey) AS supplier_count, 
           SUM(s_acctbal) AS total_account_balance,
           MAX(s_acctbal) AS max_account_balance
    FROM supplier
    GROUP BY s_nationkey
),
lineitem_details AS (
    SELECT l_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS revenue,
           AVG(l_quantity) AS avg_quantity
    FROM lineitem
    GROUP BY l_orderkey
),
part_spread AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
           DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT
       n.n_name,
       p.p_name,
       COALESCE(su.supplier_count, 0) AS total_suppliers,
       COALESCE(ps.total_avail_qty, 0) AS available_quantity,
       CASE
           WHEN ps.rank_supplycost = 1 THEN 'Top Purchase Option'
           ELSE 'Alternate Option'
       END AS supply_option,
       ld.revenue,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY ld.revenue DESC) AS revenue_rank
FROM nation n
LEFT JOIN supplier_summary su ON n.n_nationkey = su.s_nationkey
LEFT JOIN part_spread ps ON ps.ps_partkey = (
    SELECT p.p_partkey
    FROM part p
    WHERE p.p_retailprice = (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 1 AND 50)
    LIMIT 1
)
LEFT JOIN lineitem_details ld ON ld.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 1000
    )
WHERE n.n_nationkey IS NOT NULL
ORDER BY n.n_name, revenue_rank;
