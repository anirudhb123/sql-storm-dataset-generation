WITH RECURSIVE SupplyChain AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           1 AS level
    FROM partsupp
    WHERE ps_availqty > 0

    UNION ALL

    SELECT p.ps_partkey, s.s_suppkey, p.ps_availqty - 10 AS ps_availqty, 
           p.ps_supplycost + s.s_acctbal / 100 AS ps_supplycost, 
           level + 1
    FROM SupplyChain sc
    JOIN partsupp p ON p.ps_partkey = sc.ps_partkey
    JOIN supplier s ON s.s_suppkey = sc.ps_suppkey
    WHERE p.ps_availqty - 10 > 0 AND level < 3
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_within_segment,
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS overall_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderSummaries AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           COALESCE(MAX(l.l_quantity), 0) AS max_quantity,
           COALESCE(SUM(l.l_extendedprice), 0) AS total_sales
    FROM supplier s
    LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
FinalReport AS (
    SELECT cs.c_name, cs.c_acctbal, os.total_revenue, 
           si.total_sales,
           cblevel.level,
           ROW_NUMBER() OVER (PARTITION BY cs.rank_within_segment ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM CustomerStats cs
    LEFT JOIN OrderSummaries os ON cs.c_custkey = os.o_custkey
    LEFT JOIN SupplierInfo si ON si.s_suppkey = os.o_custkey
    JOIN SupplyChain cblevel ON cblevel.ps_partkey = os.o_orderkey
)

SELECT f.c_name, f.c_acctbal, f.total_revenue, f.total_sales, f.level, f.revenue_rank
FROM FinalReport f
WHERE f.total_revenue IS NOT NULL 
AND f.level > 1
ORDER BY f.c_name, f.level DESC;
