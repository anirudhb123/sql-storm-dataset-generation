WITH RecursiveNation AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, rn.level + 1
    FROM nation n
    JOIN RecursiveNation rn ON n.n_regionkey = rn.n_regionkey
    WHERE rn.level < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           SUM(p.ps_supplycost) AS total_supply_cost,
           AVG(p.ps_availqty) AS avg_avail_qty
    FROM supplier s
    LEFT JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM RecursiveNation))
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
)

SELECT DISTINCT n.n_name, ss.s_name,
       COALESCE(os.o_orderkey, -1) AS latest_order,
       CASE 
           WHEN ss.total_supply_cost IS NULL THEN 'No Supply'
           WHEN ss.total_supply_cost > 1000 THEN 'High Cost'
           ELSE 'Normal Cost' 
       END AS cost_category,
       CONCAT('Account balance for ', ss.s_name, ': ', CAST(ss.s_acctbal AS VARCHAR)) AS account_info
FROM RecursiveNation n
FULL OUTER JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN OrderSummary os ON ss.s_suppkey = os.o_orderkey AND os.order_rank = 1
WHERE LENGTH(n.n_name) BETWEEN 3 AND 15
  AND (ss.avg_avail_qty IS NULL OR ss.avg_avail_qty > (SELECT AVG(ps_availqty) FROM partsupp))
  AND (n.n_name NOT LIKE '%Z%' OR ss.s_name IS NULL)
ORDER BY n.n_name, ss.total_supply_cost DESC NULLS LAST;
