WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 3
),
PartAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
),
CustomerSegment AS (
    SELECT c.c_mktsegment, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM customer c
    GROUP BY c.c_mktsegment 
),
FinalQuery AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pa.total_available_qty,
        pa.avg_supply_cost,
        os.o_orderkey,
        os.net_sales,
        cs.c_mktsegment,
        cs.customer_count
    FROM part p
    LEFT JOIN PartAggregates pa ON p.p_partkey = pa.ps_partkey
    LEFT JOIN OrderSummary os ON pa.total_available_qty > 100 AND os.o_orderdate >= '2023-01-01'
    LEFT JOIN CustomerSegment cs ON cs.customer_count > 10
)
SELECT 
    fn.p_partkey,
    fn.p_name,
    COALESCE(fn.total_available_qty, 0) AS total_available_qty,
    COALESCE(fn.avg_supply_cost, 0.00) AS avg_supply_cost,
    fn.o_orderkey,
    fn.net_sales,
    fn.c_mktsegment
FROM FinalQuery fn
WHERE fn.o_orderkey IS NULL OR fn.net_sales > 1000
ORDER BY fn.p_partkey DESC, fn.net_sales ASC;
