WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT(sh.hierarchy_path, ' -> ', s.s_name)
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.s_suppkey <> s.s_suppkey
),
PriceDetails AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_selling_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_within_segment,
        c.c_name,
        c.c_acctbal
    FROM customer c
)
SELECT
    rh.hierarchy_path,
    pd.total_supply_cost,
    cr.rank_within_segment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(ROUND(DATE_PART('day', l.l_shipdate - l.l_commitdate)), 0)) AS total_ship_days,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END) AS return_status
FROM SupplierHierarchy rh
LEFT JOIN PriceDetails pd ON rh.s_suppkey = pd.p_partkey
LEFT JOIN orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rh.s_nationkey)
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerRanked cr ON cr.c_custkey = o.o_custkey
WHERE pd.total_supply_cost IS NOT NULL
  AND cr.rank_within_segment <= 10
GROUP BY rh.hierarchy_path, pd.total_supply_cost, cr.rank_within_segment
HAVING SUM(pd.total_supply_cost) > 1000.00
ORDER BY rh.hierarchy_path, cr.rank_within_segment DESC;
