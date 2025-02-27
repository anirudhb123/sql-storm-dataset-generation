WITH RECURSIVE SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderAggregation AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS total_lineitems, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND CURRENT_DATE
    GROUP BY o.o_orderkey
)
SELECT 
    s.s_suppkey,
    s.s_name,
    COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ps.avg_supply_cost, 0.00) AS avg_supply_cost,
    CASE 
        WHEN sr.rank IS NULL THEN 'Not ranked'
        ELSE CAST(sr.rank AS VARCHAR) || ' in region'
    END AS supplier_rank,
    COALESCE(oa.total_lineitems, 0) AS total_orders,
    ROUND(oa.total_revenue, 2) AS total_revenue
FROM supplier s
LEFT JOIN SupplierRank sr ON s.s_suppkey = sr.s_suppkey
LEFT JOIN PartStats ps ON ps.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey ORDER BY ps_supplycost LIMIT 1)
LEFT JOIN OrderAggregation oa ON oa.o_orderkey = (SELECT o_orderkey FROM orders WHERE o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey) LIMIT 1)
WHERE s.s_acctbal IS NOT NULL
  AND (s.s_acctbal > (SELECT AVG(s_acctbal) * 0.9 FROM supplier) OR s.s_comment IS NOT NULL)
ORDER BY s.s_name ASC, total_revenue DESC
FETCH FIRST 100 ROWS ONLY;
