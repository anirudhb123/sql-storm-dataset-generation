WITH RECURSIVE RegionSuppliers AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN RegionSuppliers rs ON n.n_nationkey = rs.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < rs.s_acctbal
),
AggregatedOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spend
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_custkey
),
CustomerSegments AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COALESCE(ao.total_spend, 0) AS total_spend
    FROM customer c
    LEFT JOIN AggregatedOrders ao ON c.c_custkey = ao.o_custkey
),
SupplierLineItems AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY s.s_suppkey
)
SELECT 
    rs.n_name AS nation_name,
    cs.c_name AS customer_name,
    cs.c_mktsegment AS market_segment,
    cs.total_spend,
    COALESCE(sli.total_sales, 0) AS supplier_sales,
    ROW_NUMBER() OVER (PARTITION BY cs.c_mktsegment ORDER BY cs.total_spend DESC) AS rank
FROM CustomerSegments cs
LEFT JOIN RegionSuppliers rs ON cs.c_nationkey = rs.n_nationkey
LEFT JOIN SupplierLineItems sli ON rs.s_suppkey = sli.s_suppkey
WHERE cs.total_spend > 10000
ORDER BY nation_name, rank;
