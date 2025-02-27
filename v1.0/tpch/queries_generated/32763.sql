WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartPricing AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_sales > 50000
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       p.p_name AS part_name,
       pp.p_retailprice AS part_price,
       pp.total_supply_cost,
       COALESCE(ts.total_sales, 0) AS supplier_sales,
       sh.level AS supplier_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartPricing pp ON pp.p_partkey IN (SELECT ps.ps_partkey
                                              FROM partsupp ps
                                              WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE pp.total_supply_cost > 100 AND sh.level IS NOT NULL
ORDER BY region_name, nation_name, part_name;
