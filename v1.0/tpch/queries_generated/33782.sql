WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal < ch.c_acctbal
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate < '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierDemand AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RegionAnalysis AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
FinalReport AS (
    SELECT
        ch.c_name,
        ch.c_acctbal,
        os.total_sales,
        os.item_count,
        sd.total_availqty,
        sd.max_supplycost,
        ra.nation_count
    FROM CustomerHierarchy ch
    LEFT JOIN OrdersSummary os ON ch.c_custkey = os.o_orderkey
    LEFT JOIN SupplierDemand sd ON ch.c_custkey = sd.s_suppkey
    LEFT JOIN RegionAnalysis ra ON ra.nation_count IS NOT NULL
)
SELECT 
    *
FROM FinalReport
WHERE total_sales > 5000
ORDER BY c_acctbal DESC
LIMIT 10;
