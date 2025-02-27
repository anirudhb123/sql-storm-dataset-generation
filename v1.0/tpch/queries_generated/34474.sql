WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > 20000
),
AggregateData AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        AVG(l.l_discount) AS avg_discount,
        COUNT(DISTINCT o.o_orderkey) AS number_of_orders
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE p.p_retailprice > 50.00 AND l.l_returnflag = 'N'
    GROUP BY p.p_partkey
),
FilteredNations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name LIKE '%Americas%'
)
SELECT
    ad.p_partkey,
    ad.total_supply_cost,
    ad.avg_discount,
    ad.number_of_orders,
    fn.n_name AS nation_name,
    CASE 
        WHEN ad.total_supply_cost > 100000 THEN 'High'
        WHEN ad.total_supply_cost BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS supply_cost_category
FROM AggregateData ad
JOIN FilteredNations fn ON fn.n_nationkey IN (SELECT s_nationkey FROM SupplierHierarchy)
ORDER BY ad.total_supply_cost DESC
LIMIT 10;
