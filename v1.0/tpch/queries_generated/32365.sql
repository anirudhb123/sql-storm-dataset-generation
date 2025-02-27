WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
        WHERE s2.s_nationkey = s.s_nationkey
    )
),
OrderAggregates AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
IncomeComparison AS (
    SELECT sd.s_name, sd.s_acctbal, pa.total_available, ra.r_name,
           NTILE(4) OVER (PARTITION BY ra.r_name ORDER BY sd.s_acctbal DESC) AS income_quartile
    FROM SupplierDetails sd
    LEFT JOIN PartSuppliers pa ON sd.s_suppkey = pa.ps_partkey
    JOIN region ra ON ra.r_regionkey = sd.nation_name
    WHERE pa.total_available IS NOT NULL
)
SELECT DISTINCT s.s_name, oc.total_revenue, ic.income_quartile
FROM SupplierDetails s
LEFT JOIN OrderAggregates oc ON oc.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o)
JOIN IncomeComparison ic ON s.s_name = ic.s_name
WHERE ic.income_quartile IS NOT NULL
ORDER BY oc.total_revenue DESC, s.s_name;
