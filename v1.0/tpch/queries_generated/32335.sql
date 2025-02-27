WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggregateLineItems AS (
    SELECT l.l_partkey, 
           SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price, 
           MIN(l.l_shipdate) AS first_ship_date
    FROM lineitem l
    GROUP BY l.l_partkey
),
NationWithSuppliers AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM nation n 
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_type, 
    p.p_brand, 
    COALESCE(sum_li.total_quantity, 0) AS total_quantity,
    COALESCE(sum_li.avg_price, 0) AS avg_price_per_unit,
    nws.supplier_count,
    nws.total_account_balance,
    r.r_name AS region_name
FROM part p
LEFT JOIN AggregateLineItems sum_li ON p.p_partkey = sum_li.l_partkey
JOIN NationWithSuppliers nws ON nws.n_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IN (SELECT DISTINCT sh.s_suppkey FROM SupplierHierarchy sh)
    LIMIT 1
)
JOIN region r ON nws.n_nationkey = r.r_regionkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_type = p.p_type
)
ORDER BY p.p_partkey DESC
LIMIT 100;
