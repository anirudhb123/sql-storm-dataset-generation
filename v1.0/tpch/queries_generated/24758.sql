WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_retailprice, 0 AS recursion_level
    FROM part
    WHERE p_size < 20

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_retailprice, rp.recursion_level + 1
    FROM part p
    JOIN RecursivePart rp ON p.p_partkey = rp.p_partkey + 1
    WHERE rp.recursion_level < 5
),

SupplierSummary AS (
    SELECT s.s_suppkey, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           AVG(s.s_acctbal) AS avg_acctbal,
           MAX(s.s_acctbal) AS max_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),

OrderMetrics AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total,
           MIN(o.o_orderdate) AS first_order_date,
           MAX(o.o_orderdate) AS last_order_date,
           COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),

FinalReport AS (
    SELECT rp.p_name,
           ss.total_parts,
           ss.total_supply_cost,
           om.total,
           om.line_count,
           DENSE_RANK() OVER (ORDER BY om.total DESC) AS price_rank
    FROM RecursivePart rp
    JOIN SupplierSummary ss ON rp.p_partkey = ss.s_suppkey
    FULL OUTER JOIN OrderMetrics om ON ss.total_parts = om.line_count
)

SELECT fr.p_name,
       COALESCE(fr.total_supply_cost, 0) AS adjusted_supply_cost,
       CASE 
           WHEN fr.price_rank IS NULL THEN 'Unranked'
           ELSE CAST(fr.price_rank AS VARCHAR)
       END AS rank_status
FROM FinalReport fr
WHERE fr.total IS NOT NULL
   OR fr.total_supply_cost IS NOT NULL
ORDER BY fr.price_rank ASC, fr.adjUSTed_supply_cost DESC
LIMIT 100
OFFSET CASE WHEN RANDOM() < 0.5 THEN 0 ELSE (SELECT COUNT(*) FROM FinalReport) END;
